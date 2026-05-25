const BACKEND_URL = ""; // অটো-ডিটেকশন রুট পাথ মেকানিজম

let scene, camera, renderer, loader;
let uploadedFiles = [];
let currentGameState = {};

function init3D() {
    const zone = document.getElementById('preview-zone');
    if (!zone) return;
    
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x121212);

    camera = new THREE.PerspectiveCamera(75, zone.clientWidth / zone.clientHeight, 0.1, 1000);
    camera.position.set(0, 3, 5);

    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(zone.clientWidth, zone.clientHeight);
    zone.appendChild(renderer.domElement);

    const light = new THREE.AmbientLight(0xffffff, 0.9);
    scene.add(light);
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.7);
    dirLight.position.set(5, 10, 7);
    scene.add(dirLight);

    loader = new THREE.GLTFLoader();

    window.addEventListener('resize', () => {
        camera.aspect = zone.clientWidth / zone.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(zone.clientWidth, zone.clientHeight);
    });

    function animate() {
        requestAnimationFrame(animate);
        scene.traverse((child) => {
            if (child.isMesh && child.name !== "ground") {
                child.rotation.y += 0.004;
            }
        });
        renderer.render(scene, camera);
    }
    animate();
}

document.getElementById('file-input').addEventListener('change', function(e) {
    const files = e.target.files;
    for(let file of files) {
        uploadedFiles.push(file.name);
        appendChat(file.name + " সফলভাবে আপলোড হয়েছে!", "user");

        const url = URL.createObjectURL(file);
        loader.load(url, function(gltf) {
            gltf.scene.position.set((Math.random() - 0.5) * 4, 0, (Math.random() - 0.5) * 4);
            scene.add(gltf.scene);
        }, undefined, function(error) {
            console.error("3D Model loading failed:", error);
        });
    }
});

function appendChat(text, sender) {
    const chat = document.getElementById('chat-history');
    const msg = document.createElement('div');
    msg.className = `msg ${sender}`;
    msg.innerText = text;
    chat.appendChild(msg);
    chat.scrollTop = chat.scrollHeight;
}

async function sendToAI() {
    const prompt = document.getElementById('ai-prompt').value;
    const name = document.getElementById('game-name').value;
    const desc = document.getElementById('game-desc').value;

    if(!prompt) return alert("দয়া করে গেমের আইডিয়া বা এডিট কমান্ড লিখুন!");

    appendChat(prompt, "user");
    document.getElementById('ai-prompt').value = "";
    document.getElementById('loading').style.display = "block";

    try {
        const response = await fetch(`${BACKEND_URL}/generate-game`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                game_name: name,
                description: desc,
                prompt: prompt,
                assets: uploadedFiles,
                current_state: currentGameState
            })
        });

        const data = await response.json();
        currentGameState = data.game_state;
        appendChat("Ignite3D AI: " + data.ai_comment, "ai");
    } catch (error) {
        appendChat("Ignite3D Core Error: সার্ভার মেকানিজম রেসপন্স করছে না।", "ai");
    } finally {
        document.getElementById('loading').style.display = "none";
    }
}

function downloadAPK() {
    if (!currentGameState.game_name) {
        return alert("প্রথমে গেম জেনারেট বা এডিট করুন, তারপর APK এক্সপোর্ট করুন!");
    }
    alert("আপনার কাস্টম হাই-গ্রাফিক্স কোড কম্পাইল করা হচ্ছে। ক্লাউড সার্ভার সোর্স কোড ডাউনলোড ফাইল প্রস্তুত করছে...");
    window.open(`${BACKEND_URL}/download-build?game=${currentGameState.game_name}`, '_blank');
}

window.onload = init3D;
