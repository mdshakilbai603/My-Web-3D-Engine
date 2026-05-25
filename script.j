// Render.com-এ আপনার ব্যাকএন্ড ডিপ্লয় করার পর সেই ইউআরএলটি এখানে বসাবেন
const BACKEND_URL = "https://your-backend-name.onrender.com"; 

let scene, camera, renderer, loader;
let uploadedFiles = [];
let currentGameState = {};

// Three.js 3D প্রিভিউ জোন সেটআপ
function init3D() {
    const zone = document.getElementById('preview-zone');
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x121212);

    camera = new THREE.PerspectiveCamera(75, zone.clientWidth / zone.clientHeight, 0.1, 1000);
    camera.position.set(0, 3, 5);

    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(zone.clientWidth, zone.clientHeight);
    zone.appendChild(renderer.domElement);

    // লাইটিং
    const light = new THREE.AmbientLight(0xffffff, 0.8);
    scene.add(light);
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.6);
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
                child.rotation.y += 0.005; // থ্রিডি ফাইলগুলো আলতো করে ঘুরবে
            }
        });
        renderer.render(scene, camera);
    }
    animate();
}

// .glb ফাইল আপলোড হ্যান্ডলার
document.getElementById('file-input').addEventListener('change', function(e) {
    const files = e.target.files;
    for(let file of files) {
        uploadedFiles.push(file.name);
        appendChat(file.name + " আপলোড হয়েছে!", "user");

        // Three.js প্রিভিউতে লোড করা (ভার্চুয়াল লজিক)
        const url = URL.createObjectURL(file);
        loader.load(url, function(gltf) {
            gltf.scene.position.set((Math.random() - 0.5) * 3, 0, (Math.random() - 0.5) * 3);
            scene.add(gltf.scene);
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

// AI-এর কাছে আইডিয়া পাঠানো বা এডিট করা
async function sendToAI() {
    const prompt = document.getElementById('ai-prompt').value;
    const name = document.getElementById('game-name').value;
    const desc = document.getElementById('game-desc').value;

    if(!prompt) return alert("দয়া করে গেমের আইডিয়া লিখুন!");

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
        currentGameState = data.game_state; // সার্ভার থেকে পাওয়া নতুন গেম স্টেট সেভ রাখা
        appendChat("AI: " + data.ai_comment, "ai");
    } catch (error) {
        appendChat("AI: দুঃখিত, ব্যাকএন্ড সার্ভারের সাথে যোগাযোগ করা যাচ্ছে না।", "ai");
    } finally {
        document.getElementById('loading').style.display = "none";
    }
}

// APK ডাউনলোডের রিকোয়েস্ট
function downloadAPK() {
    if (!currentGameState.game_name) {
        return alert("প্রথমে গেম জেনারেট করুন, তারপর APK বিল্ড করুন!");
    }
    alert("আপনার গেমের আর্কিটেকচার কমপ্লিট! 'Ignite3D ক্লাউড কম্পাইলার' ব্যাকএন্ডে হাই-গ্রাফিক্স কোড যুক্ত করছে। APK ডাউনলোডের লিংক ইমেইলে বা এখানে তৈরি হচ্ছে...");
    window.open(`${BACKEND_URL}/download-build?game=${currentGameState.game_name}`, '_blank');
}

window.onload = init3D;
