document.addEventListener('DOMContentLoaded', () => {
    if (window.lucide) window.lucide.createIcons();
    const marca = document.getElementById('IdMarca');
    if (marca) marca.addEventListener('change', () => {
        document.getElementById('IdModelo').value = '';
        marca.form.requestSubmit();
    });
});
