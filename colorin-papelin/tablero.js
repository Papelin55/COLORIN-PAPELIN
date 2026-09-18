const canvas = document.getElementById('tableroDibujo');
    const ctx = canvas.getContext('2d');
    const contenedor = document.getElementById('contenedorTablero');
    
    const colorPicker = document.getElementById('colorPicker');
    const swatches = document.querySelectorAll('.color-swatch');
    const grosorPincel = document.getElementById('grosorPincel');
    const valorGrosor = document.getElementById('valorGrosor');
    const opacidadPincel = document.getElementById('opacidadPincel');
    const valorOpacidad = document.getElementById('valorOpacidad');
    
    const btnLimpiar = document.getElementById('btnLimpiar');
    const btnGuardar = document.getElementById('btnGuardar');
    const botones = document.querySelectorAll('.panel-herramientas .btn-dibujo');

    let dibujando = false;
    let modoActual = 'pincel'; 
    let tipoPincel = 'normal'; 
    let figuraActual = 'linea';
    
    let colorActual = colorPicker.value;
    let grosorActual = grosorPincel.value;
    let opacidadActual = 1;
    let hueMagico = 0;
    
    let inicioX = 0; let inicioY = 0; let capaGuardada;

    function redimensionarCanvas() {
        const tempCanvas = document.createElement('canvas');
        tempCanvas.width = canvas.width; tempCanvas.height = canvas.height;
        tempCanvas.getContext('2d').drawImage(canvas, 0, 0);

        canvas.width = contenedor.clientWidth - 40;
        canvas.height = contenedor.clientHeight - 40;
        
        ctx.lineCap = 'round'; ctx.lineJoin = 'round';
        ctx.drawImage(tempCanvas, 0, 0);
    }
    window.addEventListener('resize', redimensionarCanvas);
    window.onload = redimensionarCanvas;

    botones.forEach(boton => {
        boton.addEventListener('click', () => {
            if (boton.dataset.mode) {
                document.querySelectorAll('[data-mode]').forEach(b => b.classList.remove('activo'));
                modoActual = boton.dataset.mode;
            } else if (boton.dataset.brush) {
                document.querySelectorAll('[data-brush]').forEach(b => b.classList.remove('activo'));
                modoActual = 'pincel';
                document.querySelector('[data-mode="pincel"]').classList.add('activo');
                tipoPincel = boton.dataset.brush;
            } else if (boton.dataset.shape) {
                document.querySelectorAll('[data-shape]').forEach(b => b.classList.remove('activo'));
                modoActual = 'figura';
                figuraActual = boton.dataset.shape;
            }
            boton.classList.add('activo');
        });
    });

    document.getElementById('papelBlanco').addEventListener('click', (e) => { cambiarPapel(e, ''); });
    document.getElementById('papelCuadricula').addEventListener('click', (e) => { cambiarPapel(e, 'papel-cuadricula'); });
    document.getElementById('papelPuntos').addEventListener('click', (e) => { cambiarPapel(e, 'papel-puntos'); });

    function cambiarPapel(e, clase) {
        canvas.className = clase;
        document.querySelectorAll('#papelBlanco, #papelCuadricula, #papelPuntos').forEach(b => b.classList.remove('activo'));
        e.currentTarget.classList.add('activo');
    }

    function iniciar(e) {
        const rect = canvas.getBoundingClientRect();
        inicioX = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
        inicioY = (e.touches ? e.touches[0].clientY : e.clientY) - rect.top;

        if (modoActual === 'relleno') {
            ejecutarRelleno(Math.floor(inicioX), Math.floor(inicioY), colorActual);
            return;
        }

        dibujando = true;
        ctx.beginPath();
        ctx.moveTo(inicioX, inicioY);

        if (modoActual === 'figura') {
            capaGuardada = ctx.getImageData(0, 0, canvas.width, canvas.height);
        } else if (modoActual === 'pincel' && tipoPincel === 'normal') {
            dibujar(e);
        }
    }

    function dibujar(e) {
        if (!dibujando) return;
        const rect = canvas.getBoundingClientRect();
        const actualX = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
        const actualY = (e.touches ? e.touches[0].clientY : e.clientY) - rect.top;

        ctx.lineWidth = grosorActual;
        ctx.globalAlpha = opacidadActual;

        if (modoActual === 'borrador') {
            ctx.strokeStyle = '#ffffff';
            ctx.globalAlpha = 1;
        } else if (tipoPincel === 'rainbow' && modoActual === 'pincel') {
            ctx.strokeStyle = `hsl(${hueMagico}, 100%, 60%)`;
            hueMagico = (hueMagico + 4) % 360;
        } else {
            ctx.strokeStyle = colorActual;
            ctx.fillStyle = colorActual;
        }

        if (modoActual === 'pincel') {
            ctx.lineCap = 'round'; ctx.lineJoin = 'round';
            if (tipoPincel === 'normal' || tipoPincel === 'rainbow') {
                ctx.lineTo(actualX, actualY); ctx.stroke();
            } else if (tipoPincel === 'caligrafico') {
                ctx.lineCap = 'square'; ctx.lineTo(actualX, actualY); ctx.stroke();
            } else if (tipoPincel === 'spray') {
                for (let i = 0; i < 15; i++) {
                    const r = grosorActual * 1.8;
                    const x = actualX + (Math.random() - 0.5) * r;
                    const y = actualY + (Math.random() - 0.5) * r;
                    ctx.fillRect(x, y, 1.5, 1.5);
                }
            }
        } else if (modoActual === 'borrador') {
            ctx.lineTo(actualX, actualY); ctx.stroke();
        } else if (modoActual === 'figura') {
            ctx.putImageData(capaGuardada, 0, 0);
            ctx.beginPath();
            if (figuraActual === 'linea') {
                ctx.moveTo(inicioX, inicioY); ctx.lineTo(actualX, actualY); ctx.stroke();
            } else if (figuraActual === 'rectangulo') {
                ctx.strokeRect(inicioX, inicioY, actualX - inicioX, actualY - inicioY);
            } else if (figuraActual === 'circulo') {
                let rad = Math.sqrt(Math.pow(actualX - inicioX, 2) + Math.pow(actualY - inicioY, 2));
                ctx.arc(inicioX, inicioY, rad, 0, 2 * Math.PI); ctx.stroke();
            }
        }
    }

    function detener() { dibujando = false; ctx.beginPath(); ctx.globalAlpha = 1; }

    function ejecutarRelleno(startX, startY, colorHex) {
        const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const data = imgData.data;
        
        const rTarget = parseInt(colorHex.substr(1,2), 16);
        const gTarget = parseInt(colorHex.substr(3,2), 16);
        const bTarget = parseInt(colorHex.substr(5,2), 16);
        
        const posInIdata = (startY * canvas.width + startX) * 4;
        const rStart = data[posInIdata];
        const gStart = data[posInIdata+1];
        const bStart = data[posInIdata+2];
        const aStart = data[posInIdata+3];

        if (rStart === rTarget && gStart === gTarget && bStart === bTarget && aStart === 255) return;

        const listaPixeles = [[startX, startY]];
        while(listaPixeles.length > 0) {
            const [x, y] = listaPixeles.pop();
            const pos = (y * canvas.width + x) * 4;

            if (x >= 0 && x < canvas.width && y >= 0 && y < canvas.height) {
                if (data[pos] === rStart && data[pos+1] === gStart && data[pos+2] === bStart && data[pos+3] === aStart) {
                    data[pos] = rTarget; data[pos+1] = gTarget; data[pos+2] = bTarget; data[pos+3] = 255;
                    listaPixeles.push([x+1, y]); listaPixeles.push([x-1, y]);
                    listaPixeles.push([x, y+1]); listaPixeles.push([x, y-1]);
                }
            }
        }
        ctx.putImageData(imgData, 0, 0);
    }

    canvas.addEventListener('mousedown', iniciar); canvas.addEventListener('mousemove', dibujar);
    canvas.addEventListener('mouseup', detener); canvas.addEventListener('mouseout', detener);
    canvas.addEventListener('touchstart', (e) => { e.preventDefault(); iniciar(e); });
    canvas.addEventListener('touchmove', (e) => { e.preventDefault(); dibujar(e); });
    canvas.addEventListener('touchend', detener);

    // INTERACCIÓN INTELIGENTE DE COLORES:
    
    // 1. Entrada desde el colorPicker grande
    colorPicker.addEventListener('input', (e) => {
        colorActual = e.target.value;
        // Quitamos la marca visual de los círculos rápidos si se escoge uno personalizado
        swatches.forEach(s => s.classList.remove('activo-swatch'));
    });

    // 2. Entrada al pulsar los círculos de colores populares
    swatches.forEach(swatch => {
        swatch.addEventListener('click', (e) => {
            // Desmarcar círculo previo y marcar el actual
            swatches.forEach(s => s.classList.remove('activo-swatch'));
            e.target.classList.add('activo-swatch');
            
            // Actualizar variables de dibujo e igualar el colorPicker grande
            colorActual = e.target.dataset.color;
            colorPicker.value = colorActual;
        });
    });

    grosorPincel.addEventListener('input', (e) => { grosorActual = e.target.value; valorGrosor.textContent = `${grosorActual}px`; });
    opacidadPincel.addEventListener('input', (e) => { opacidadActual = e.target.value; valorOpacidad.textContent = `${Math.round(opacidadActual * 100)}%`; });

    btnLimpiar.addEventListener('click', () => { if (confirm('¿Vaciar lienzo?')) ctx.clearRect(0, 0, canvas.width, canvas.height); });

    btnGuardar.addEventListener('click', () => {
        const canvasFinal = document.createElement('canvas');
        canvasFinal.width = canvas.width; canvasFinal.height = canvas.height;
        const ctxFinal = canvasFinal.getContext('2d');

        if (canvas.classList.contains('papel-cuadricula')) {
            ctxFinal.fillStyle = '#ffffff'; ctxFinal.fillRect(0,0,canvas.width,canvas.height);
            ctxFinal.strokeStyle = '#edf2f7'; ctxFinal.lineWidth = 1;
            for(let x=0; x<canvas.width; x+=20){ ctxFinal.beginPath(); ctxFinal.moveTo(x,0); ctxFinal.lineTo(x,canvas.height); ctxFinal.stroke(); }
            for(let y=0; y<canvas.height; y+=20){ ctxFinal.beginPath(); ctxFinal.moveTo(0,y); ctxFinal.lineTo(canvas.width,y); ctxFinal.stroke(); }
        } else if (canvas.classList.contains('papel-puntos')) {
            ctxFinal.fillStyle = '#ffffff'; ctxFinal.fillRect(0,0,canvas.width,canvas.height);
            ctxFinal.fillStyle = '#cbd5e1';
            for(let x=10; x<canvas.width; x+=20){ for(let y=10; y<canvas.height; y+=20){ ctxFinal.beginPath(); ctxFinal.arc(x,y,1.5,0,2*Math.PI); ctxFinal.fill(); } }
        } else {
            ctxFinal.fillStyle = '#ffffff'; ctxFinal.fillRect(0,0,canvas.width,canvas.height);
        }

        ctxFinal.drawImage(canvas, 0, 0);
        const enlace = document.createElement('a');
        enlace.download = 'Mi-Arte-ColorinPapelin.png';
        enlace.href = canvasFinal.toDataURL('image/png');
        enlace.click();
    });
