const stage = document.getElementById('stage');

  const dots = [
    {x:70,  y:65,  r:12, c:'#D4936A', d:0.10},
    {x:780, y:58,  r:10, c:'#B45F32', d:0.15},
    {x:55,  y:500, r:9,  c:'#C27840', d:0.20},
    {x:805, y:480, r:11, c:'#E8B98A', d:0.18},
    {x:180, y:40,  r:7,  c:'#93461F', d:0.25},
    {x:670, y:44,  r:8,  c:'#D4936A', d:0.22},
    {x:42,  y:300, r:8,  c:'#B45F32', d:0.12},
    {x:820, y:290, r:8,  c:'#C27840', d:0.14},
    {x:130, y:560, r:7,  c:'#D4936A', d:0.30},
    {x:730, y:550, r:8,  c:'#93461F', d:0.28},
    {x:430, y:30,  r:6,  c:'#B45F32', d:0.35},
    {x:250, y:575, r:6,  c:'#C27840', d:0.32},
  ];

  dots.forEach(d => {
    const el = document.createElement('div');
    el.className = 'dot';
    el.style.cssText =
      `width:${d.r*2}px;height:${d.r*2}px;` +
      `left:${d.x - d.r}px;top:${d.y - d.r}px;` +
      `background:${d.c};animation-delay:${d.d}s;`;
    stage.appendChild(el);
  });

  const squares = [
    {x:155, y:46,  c:'#C27840', d:0.40, rot:20},
    {x:698, y:50,  c:'#B45F32', d:0.38, rot:-18},
    {x:85,  y:420, c:'#D4936A', d:0.50, rot:30},
    {x:768, y:410, c:'#93461F', d:0.45, rot:-25},
    {x:380, y:565, c:'#C27840', d:0.55, rot:15},
    {x:510, y:38,  c:'#E8B98A', d:0.42, rot:-12},
  ];

  squares.forEach(s => {
    const el = document.createElement('div');
    el.className = 'confetti-sq';
    el.style.cssText =
      `left:${s.x}px;top:${s.y}px;` +
      `background:${s.c};animation-delay:${s.d}s;` +
      `transform:rotate(${s.rot}deg);`;
    stage.appendChild(el);
  });
