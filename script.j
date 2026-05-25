const BACKEND_URL = ""; // অটো-ডিটেকশন রুট পাথ মেকানিজম

let scene, camera, renderer, loader, controls;
let uploadedFiles = [];
let currentGameState = {};

function init3D() {
    const zone = document.getElementById('preview-zone');
    if (!zone) return;
    
    // ১. সিন (Scene) তৈরি
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0d0e12); // নতুন মিনিমাল ডার্ক ব্যাকগ্রাউন্ড

    // ২. ক্যামেরা (Camera) সেটআপ - অল ডিভাইস ফ্রেন্ডলি ভিউ
    camera = new THREE.PerspectiveCamera(60, zone.clientWidth / zone.clientHeight, 0.1, 1000);
    camera.position.set(0, 4, 8);

    // ৩. রেন্ডারার (Renderer) - মোবাইল ও হাই-এন্ড স্ক্রিন অপ্টিমাইজড
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: "high-performance" });
    renderer.setSize(zone.clientWidth, zone.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // অতিরিক্ত পিক্সেল ড্রপ কমিয়ে পারফরম্যান্স বাড়াবে
    renderer.shadowMap.enabled = true;
    zone.appendChild(renderer.domElement);

    // ৪. লাইটিং (Lighting) - ৩ডি অবজেক্ট উজ্জ্বল দেখানোর জন্য
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.0); // সবদিক থেকে সমান আলো
    scene.add(ambientLight);
    
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8); // রোদের মতো ডিরেকশনাল আলো
    dirLight.position.set(10, 20, 15);
    dirLight.castShadow = true;
    scene.add(dirLight);

    // ৫. গ্রাউন্ড বা মেঝের গ্রিড (পাবজি/ফ্রি-ফায়ারের ভার্চুয়াল গ্রাউন্ড ফিল্ড)
    const gridHelper = new THREE.GridHelper(60, 60, 0x444444, 0x222222);
    gridHelper.position.y = -0.01;
    scene.add(gridHelper);

    // ৬. থ্রিডি ফাইল লোডার (GLTFLoader)
    loader = new THREE.GLTFLoader();

    // ৭. ক্যামেরা টাচ ও মাউস কন্ট্রোল (OrbitControls) - "টিভি" প্রিভিউ স্ক্রিন ঘুরিয়ে দেখার ম্যাজিক
    // এটি থ্রিডি লাইব্রেরি থেকে স্ক্রিপ্ট আকারে index.htm এ অলরেডি ইন্টিগ্রেট করা প্যানেল রিড করবে
    if (typeof THREE.OrbitControls !== 'undefined') {
        controls = new THREE.OrbitControls(camera, renderer.domElement);
    } else {
        // যদি মেইন লাইব্রেরি ব্যাকআপ হিসেবে লোড হতে সময় নেয়, তবে সিডিএন থেকে ইনস্ট্যান্ট তৈরি করবে
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js';
        script.onload = () => {
            controls = new THREE.OrbitControls(camera, renderer.domElement);
            controls.enableDamping = true;
            controls.dampingFactor = 0.05;
            controls.maxPolarAngle = Math.PI / 2 - 0.05; // মাটিকে নিচে যেতে দেবে না
            controls.minDistance = 2;
            controls.maxDistance = 50;
        };
        document.head.appendChild(script);
    }

    // ৮. রেসপনসিভ স্ক্রিন হ্যান্ডলার (মোবাইল/ট্যাবলেট স্ক্রিন ঘুরিয়ে ধরলে বা সাইজ বদলালে অটো ফিট হবে)
    window.addEventListener('resize', () => {
        const width = zone.clientWidth;
        const height = zone.clientHeight;
        
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
        
        renderer.setSize(width, height);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    });

    // ৯. অ্যানিমেশন লুপ (গেম এনভায়রনমেন্ট ফ্রেম রেন্ডারার)
    function animate() {
        requestAnimationFrame(animate);
        
        if (controls) controls.update(); // মাউস বা টাচ মুভমেন্ট আপডেট
        
        scene.traverse((child) => {
            if (child.isMesh && child.name !== "ground" && !child.isGridHelper) {
                // অবজেক্টগুলো হালকা রিদমে ঘুরবে যতক্ষণ না ইউজার নিজে টাচ করছে
                if(!controls || !controls.state == -1) {
                    child.rotation.y += 0.002;
                }
            }
        });
        
        renderer.render(scene, camera);
    }
    animate();
}

// ফাইল আপলোড ও থ্রিডি প্রিভিউ জোন ইজেকশন লজিক
document.getElementById('file-input').addEventListener('change', function(e) {
    const files = e.target.files;
    for(let file of files) {
        uploadedFiles.push(file.name);
        appendChat(file.name + " সফলভাবে আপলোড হয়েছে!", "user");

        const url = URL.createObjectURL(file);
        loader.load(url, function(gltf) {
            const model = gltf.scene;
            
            // মডেলের সাইজ সব ডিভাইসের জন্য অটো-স্কেল (Auto Scale) করা
            const box = new THREE.Box3().setFromObject(model);
            const size = box.getSize(new THREE.Vector3()).length();
            const center = box.getCenter(new THREE.Vector3());
            
            model.position.x += (Math.random() - 0.5) * 5;
            model.position.z += (Math.random() - 0.5) * 5;
            model.position.y = 0; // মাটির উপরে স্থাপন
            
            // সাইজ খুব বড় বা ছোট হলে স্ট্যান্ডার্ড ১.৫ ইউনিটে ফিট করবে
            if(size > 5) {
                model.scale.setScalar(5 / size);
            }

            scene.add(model);
            
            // ক্যামেরাকে নতুন মডেলের দিকে ফোকাস করানো
            if(controls) {
                controls.target.set(model.position.x, 1, model.position.z);
            }
            
        }, undefined, function(error) {
            console.error("3D Model loading failed:", error);
            appendChat("ইঞ্জিন কোড এরর: .glb ফাইলটি রেন্ডার করা যায়নি।", "ai");
        });
    }
});

function appendChat(text, sender) {
    const chat = document.getElementById('chat-history');
    if (!chat) return;
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
    document.getElementById('loading').style.display = "flex"; // মডার্ন ফ্লেক্স লোডার অ্যাক্টিভেশন

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
        appendChat("Ignite3D Core Error: ব্যাকএন্ড ক্লাউড সার্ভার রেসপন্স করছে না।", "ai");
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

// ডোমেস্টিক উইন্ডো লোড ট্রিগার
window.onload = init3D;
