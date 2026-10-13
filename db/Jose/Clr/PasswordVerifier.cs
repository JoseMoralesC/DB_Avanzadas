using System;
using System.Data.SqlTypes;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using Microsoft.SqlServer.Server;

namespace Repuestos.Passwords
{
    public static class PasswordVerifier
    {
        // Decode the Identity envelope; Windows CNG computes PBKDF2 in native code.
        [SqlFunction(IsDeterministic = true, IsPrecise = true, DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None)]
        public static SqlBoolean Verify(SqlString password, SqlString encodedHash)
        {
            if (password.IsNull || encodedHash.IsNull || password.Value.Length > 256 || encodedHash.Value.Length > 255)
                return SqlBoolean.False;
            try
            {
                byte[] payload = Convert.FromBase64String(encodedHash.Value);
                if (payload.Length == 0) return SqlBoolean.False;
                int offset, saltLength, iterations, subkeyLength;
                string algorithm;
                if (payload[0] == 0)
                {
                    if (payload.Length != 49) return SqlBoolean.False;
                    offset = 1; saltLength = 16; iterations = 1000; subkeyLength = 32;
                    algorithm = "SHA1";
                }
                else if (payload[0] == 1 && payload.Length >= 13)
                {
                    uint prf = ReadUInt32(payload, 1);
                    uint rounds = ReadUInt32(payload, 5);
                    uint saltSize = ReadUInt32(payload, 9);
                    if (rounds < 1 || rounds > 1000000 || saltSize < 16 || saltSize > 128)
                        return SqlBoolean.False;
                    iterations = (int)rounds; saltLength = (int)saltSize; offset = 13;
                    subkeyLength = payload.Length - offset - saltLength;
                    if (subkeyLength < 16 || subkeyLength > 128) return SqlBoolean.False;
                    if (prf == 0) algorithm = "SHA1";
                    else if (prf == 1) algorithm = "SHA256";
                    else if (prf == 2) algorithm = "SHA512";
                    else return SqlBoolean.False;
                }
                else return SqlBoolean.False;
                byte[] salt = new byte[saltLength];
                byte[] expected = new byte[subkeyLength];
                Buffer.BlockCopy(payload, offset, salt, 0, saltLength);
                Buffer.BlockCopy(payload, offset + saltLength, expected, 0, subkeyLength);
                return new SqlBoolean(Equal(Derive(Encoding.UTF8.GetBytes(password.Value), salt, iterations, algorithm, subkeyLength), expected));
            }
            catch (FormatException) { return SqlBoolean.False; }
            catch (ArgumentException) { return SqlBoolean.False; }
        }

        private static byte[] Derive(byte[] password, byte[] salt, int iterations, string algorithm, int length)
        {
            IntPtr provider;
            int status = BCryptOpenAlgorithmProvider(out provider, algorithm, null, 8);
            if (status != 0) throw new CryptographicException("No se pudo abrir el proveedor PBKDF2 de Windows.");
            try
            {
                byte[] key = new byte[length];
                status = BCryptDeriveKeyPBKDF2(provider, password, password.Length, salt, salt.Length,
                    (ulong)iterations, key, key.Length, 0);
                if (status != 0) throw new CryptographicException("No se pudo verificar la clave con PBKDF2.");
                return key;
            }
            finally { BCryptCloseAlgorithmProvider(provider, 0); }
        }

        [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
        [DllImport("bcrypt.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
        private static extern int BCryptOpenAlgorithmProvider(out IntPtr provider, string algorithm, string implementation, int flags);

        [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
        [DllImport("bcrypt.dll", ExactSpelling = true)]
        private static extern int BCryptDeriveKeyPBKDF2(IntPtr provider, [In] byte[] password, int passwordLength,
            [In] byte[] salt, int saltLength, ulong iterations, [Out] byte[] key, int keyLength, int flags);

        [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
        [DllImport("bcrypt.dll", ExactSpelling = true)]
        private static extern int BCryptCloseAlgorithmProvider(IntPtr provider, int flags);

        private static uint ReadUInt32(byte[] bytes, int offset)
        {
            return ((uint)bytes[offset] << 24) | ((uint)bytes[offset + 1] << 16)
                | ((uint)bytes[offset + 2] << 8) | bytes[offset + 3];
        }

        [MethodImpl(MethodImplOptions.NoInlining | MethodImplOptions.NoOptimization)]
        private static bool Equal(byte[] actual, byte[] expected)
        {
            int difference = 0;
            for (int i = 0; i < expected.Length; i++) difference |= actual[i] ^ expected[i];
            return difference == 0;
        }
    }
}
