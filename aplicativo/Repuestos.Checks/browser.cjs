const { chromium } = require('../../.qa/node_modules/playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');

(async () => {
  fs.mkdirSync('.qa/screenshots', { recursive: true });
  const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
  let checks = 0;
  const check = (ok, message) => { assert.ok(ok, message); checks++; console.log('OK: ' + message); };
  const url = process.env.TEST_URL || 'http://localhost:5181';
  async function login(page, correo, password = 'TestRepuestos2026!') {
    await page.goto(url + '/Cuenta/Login');
    await page.locator('#Correo').fill(correo);
    await page.locator('#Contrasena').fill(password);
    await page.getByRole('button', { name: 'Ingresar' }).click();
  }
  try {
    const context = await browser.newContext({ viewport: { width: 1366, height: 900 } });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    await page.goto(url);
    check(page.url().includes('/Cuenta/Login'), 'Requiere sesion para consultar catalogo');
    await page.screenshot({ path: '.qa/screenshots/login-desktop.png', fullPage: true });
    await login(page, 'admin@test.local', 'incorrecta');
    check(await page.getByText('Credenciales incorrectas o cuenta no disponible.').isVisible(), 'Login incorrecto muestra error');
    await login(page, 'admin@test.local');
    check(await page.getByRole('heading', { name: 'Catalogo de repuestos' }).isVisible(), 'Admin inicia sesion');
    check(await page.locator('svg.lucide').count() > 0, 'Iconos locales renderizados');
    await page.getByRole('link', { name: 'Conexion', exact: true }).click();
    check(await page.getByText('RepuestosJose_QA', { exact: true }).isVisible(), 'Solo modifica la base SQL aislada');
    await page.getByRole('link', { name: 'Catalogo', exact: true }).first().click();
    await page.screenshot({ path: '.qa/screenshots/catalogo-desktop.png', fullPage: true });
    await page.getByRole('link', { name: 'Nuevo repuesto' }).click();
    check(await page.locator('#Codigo').textContent() === 'Pendiente', 'Alta muestra codigo pendiente sin campo editable');
    check(await page.locator('input[name=Codigo]').count() === 0, 'El navegador no envia codigo manual');
    await page.locator('#IdCategoria').selectOption('1');
    await page.locator('#Nombre').fill('Farol prueba navegador');
    await page.locator('#PrecioVenta').fill('1500.50');
    await page.locator('#Costo').fill('950.25');
    await page.getByRole('button', { name: 'Guardar repuesto' }).click();
    check(await page.getByText('Repuesto guardado.').isVisible(), 'Alta desde formulario MVC');
    const codigo = (await page.locator('tr', { hasText: 'Farol prueba navegador' }).locator('small').textContent()).trim();
    check(/^REP-\d{6,}$/.test(codigo), 'Alta asigna codigo automatico');
    await page.getByRole('link', { name: 'Editar ' + codigo, exact: true }).click();
    check(await page.locator('#Codigo').textContent() === codigo, 'Edicion muestra codigo original');
    check(await page.locator('#PrecioVenta').inputValue() === '1500.50', 'Conserva decimales en edicion');
    await page.locator('#Activo').uncheck();
    await page.getByRole('button', { name: 'Guardar repuesto' }).click();
    const row = page.locator('tr', { hasText: codigo });
    check(await row.getByText('Inactivo').isVisible(), 'Desactivacion desde formulario');
    await page.getByRole('link', { name: 'Conexion', exact: true }).click();
    check(await page.getByText('RepuestosJose_QA', { exact: true }).isVisible(), 'Identifica la conexion SQL real');
    const response = await context.request.post(url + '/Catalogo/Editar', { form: { Codigo: 'FORGED', IdCategoria: 1, Nombre: 'Sin token' } });
    check(response.status() === 400, 'Rechaza POST sin token antiforgery');
    await page.getByRole('button', { name: 'Cerrar sesion' }).click();
    check(page.url().includes('/Cuenta/Login'), 'Cierra sesion por POST');
    await context.close();

    const client = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const mobile = await client.newPage();
    await login(mobile, 'cliente@test.local');
    check(await mobile.getByRole('link', { name: 'Nuevo repuesto' }).count() === 0, 'Cliente no recibe accion de mantenimiento');
    check(await mobile.getByText(codigo, { exact: true }).count() === 0, 'Cliente no recibe repuesto inactivo');
    await mobile.screenshot({ path: '.qa/screenshots/catalogo-mobile.png', fullPage: true });
    check(await mobile.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), 'Sin desbordamiento de pagina en movil');
    await mobile.goto(url + '/Catalogo/Editar/1');
    check(mobile.url().includes('AccesoDenegado'), 'Servidor bloquea acceso directo del cliente a mantenimiento');
    await mobile.goto(url + '/Casos');
    check(await mobile.getByText('ABC123', { exact: true }).isVisible(), 'Cliente consulta sus casos');
    await mobile.screenshot({ path: '.qa/screenshots/casos-mobile.png', fullPage: true });
    await mobile.getByRole('button', { name: 'Cerrar sesion' }).click();
    await login(mobile, 'cliente2@test.local');
    await mobile.goto(url + '/Casos?IdUsuario=2&IdAseguradora=1');
    check(await mobile.getByText('XYZ789', { exact: true }).isVisible()
      && await mobile.getByText('ABC123', { exact: true }).count() === 0, 'Parametros del navegador no cambian identidad del cliente');
    check(errors.length === 0, 'Sin errores JavaScript en escritorio');
    await client.close();
    console.log(`${checks} comprobaciones de navegador correctas.`);
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exit(1); });
