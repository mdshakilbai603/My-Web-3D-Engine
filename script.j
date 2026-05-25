const BACKEND_URL = ""; // অটো-ডিটেকশন রুট পাথ মেকানিজম

let scene, camera, renderer, loader, controls;
let uploadedFiles = [];
let currentGameState = {};

function init3D() {
    const zone = document.getElementById('preview-zone');
    if (!zone) return;
    
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0d0e12);

    camera = new THREE.PerspectiveCamera(60, zone.clientWidth / zone.clientHeight, 0.1, 1000);
    camera.position.set(0, 5, 10);

    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: "high-performance" });
    renderer.setSize(zone.clientWidth, zone.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    zone.appendChild(renderer.domElement);

    // লাইটিং
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.2);
    scene.add(ambientLight);
    
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
    dirLight.position.set(10, 20, 15);
    scene.add(dirLight);

    // গেমের ভার্চুয়াল গ্রাউন্ড ফিল্ড গ্রিড
    const gridHelper = new THREE.GridHelper(60, 60, 0x444444, 0x222222);
    gridHelper.position.y = 0;
    scene.add(gridHelper);

    loader = new THREE.GLTFLoader();

    // OrbitControls লোড করা (ঘুরিয়ে দেখার জন্য)
    if (typeof THREE.OrbitControls !== 'undefined') {
        setupControls();
    } else {
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js';
        script.onload = setupControls;
        document.head.appendChild(script);
    }

    window.addEventListener('resize', () => {
        camera.aspect = zone.clientWidth / zone.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(zone.clientWidth, zone.clientHeight);
    });

    function animate() {
        requestAnimationFrame(animate);
        if (controls) controls.update();
        renderer.render(scene, camera);
    }
    animate();
}

function setupControls() {
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.maxPolarAngle = Math.PI / 2 - 0.05;
}

// গিটহাব ফাইল আপলোড হ্যান্ডলার
document.getElementById('file-input').addEventListener('change', function(e) {
    const files = e.target.files;
    for(let file of files) {
        uploadedFiles.push(file.name);
        appendChat(file.name + " সফলভাবে আপলোড হয়েছে!", "user");

        const url = URL.createObjectURL(file);
        loader.load(url, function(gltf) {
            const model = gltf.scene;
            model.position.set((Math.random() - 0.5) * 5, 0, (Math.random() - 0.5) * 5);
            scene.add(model);
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

// 🤖 এআই প্রম্পট অ্যানালাইসিস এবং রিয়েল-টাইম থ্রিডি অবজেক্ট জেনারেশন ইঞ্জিন
function executeAIVisualCommand(prompt) {
    const text = prompt.toLowerCase();
    
    // ১. ইউজার যদি বক্স/কিউব বা ঘর তৈরি করতে বলে
    if (text.includes("box") || text.includes("cube") || text.includes("বক্স") || text.includes("বাক্স")) {
        const geometry = new THREE.BoxGeometry(2, 2, 2);
        let color = 0xff4757; // ডিফল্ট লাল রঙ
        
        if (text.includes("blue") || text.includes("নীল")) color = 0x00d2d3;
        if (text.includes("green") || text.includes("সবুজ")) color = 0x10ac84;
        if (text.includes("white") || text.includes("সাদা")) color = 0xffffff;
        
        const material = new THREE.MeshStandardMaterial({ color: color, roughness: 0.4 });
        const cube = new THREE.Mesh(geometry, material);
        cube.position.set((Math.random() - 0.5) * 6, 1, (Math.random() - 0.5) * 6);
        scene.add(cube);
        return "ইঞ্জিন আপনার কমান্ড অনুযায়ী থ্রিডি কিউব/বক্স রেন্ডার করেছে।";
    }

    // ২. ইউজার যদি গোলক/বল তৈরি করতে বলে
    if (text.includes("sphere") || text.includes("ball") || text.includes("গোলক") || text.includes("বল")) {
        const geometry = new THREE.SphereGeometry(1.2, 32, 32);
        const material = new THREE.MeshStandardMaterial({ color: 0xff9f43, metalness: 0.1, roughness: 0.3 });
        const sphere = new THREE.Mesh(geometry, material);
        sphere.position.set((Math.random() - 0.5) * 6, 1.2, (Math.random() - 0.5) * 6);
        scene.add(sphere);
        return "ইঞ্জিন আপনার কমান্ড অনুযায়ী থ্রিডি স্পেয়ার/বল রেন্ডার করেছে।";
    }

    // ৩. ইউজার যদি ক্যারেক্টার স্পন/প্লেয়ার এনভায়রনমেন্ট তৈরি করতে বলে
    if (text.includes("player") || text.includes("character") || text.includes("প্লেয়ার") || text.includes("মানুষ")) {
        // একটি বেসিক হিউম্যানয়েড ক্যারেক্টার শেপ জেনারেট করা (মাথা ও বডি)
        const group = new THREE.Group();
        const bodyGeo = new THREE.CylinderGeometry(0.5, 0.5, 2, 16);
        const bodyMat = new THREE.MeshStandardMaterial({ color: 0x2e86de });
        const body = new THREE.Mesh(bodyGeo, bodyMat);
        body.position.y = 1;
        group.add(body);

        const headGeo = new THREE.SphereGeometry(0.4, 16, 16);
        const headMat = new THREE.MeshStandardMaterial({ color: 0xffdb9b });
        const head = new THREE.Mesh(headGeo, headMat);
        head.position.y = 2.2;
        group.add(head);

        group.position.set((Math.random() - 0.5) * 6, 0, (Math.random() - 0.5) * 6);
        scene.add(group);
        return "গেমের ক্যারেক্টার বডি মেকানিক্স এবং প্লেয়ার ক্লায়েন্ট সিন-এ সফলভাবে ইনজেক্ট করা হয়েছে।";
    }

    return null; // যদি স্পেসিফিক কোনো ম্যাচ না পাওয়া যায়
}

async function sendToAI() {
    const prompt = document.getElementById('ai-prompt').value;
    const name = document.getElementById('game-name').value;
    const desc = document.getElementById('game-desc').value;

    if(!prompt) return alert("দয়া করে গেমের আইডিয়া বা এডিট কমান্ড লিখুন!");

    appendChat(prompt, "user");
    document.getElementById('ai-prompt').value = "";
    document.getElementById('loading').style.display = "flex";

    // প্রথমে ফ্রন্টএন্ড ইঞ্জিন প্রম্পটটি নিজে অ্যানালাইসিস করে রিয়েল-টাইম অবজেক্ট স্ক্রিনে তৈরি করবে
    const visualResult = executeAIVisualCommand(prompt);

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
        
        // যদি ভিজ্যুয়াল কমান্ড রান হয়ে থাকে তবে সেটা যোগ করবে, নাহলে সার্ভার মেসেজ দেখাবে
        if(visualResult) {
            appendChat("Ignite3D AI: " + visualResult + " " + data.ai_comment, "ai");
        } else {
            appendChat("Ignite3D AI: " + data.ai_comment, "ai");
        }
    } catch (error) {
        if(visualResult) {
            appendChat("Ignite3D AI (Local): " + visualResult + " (সার্ভার অফলাইন, কিন্তু লোকাল রেন্ডার সম্পন্ন হয়েছে।)", "ai");
        } else {
            appendChat("Ignite3D Core Error: ব্যাকএন্ড ক্লাউড সার্ভার রেসপন্স করছে না।", "ai");
        }
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
