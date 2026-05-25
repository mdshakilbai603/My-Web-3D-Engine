const BACKEND_URL = ""; 

let scene, camera, renderer, loader, controls;
let uploadedFiles = [];
let currentGameState = {};

function init3D() {
    const zone = document.getElementById('preview-zone');
    if (!zone) return;
    
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x1a1c23); // মডার্ন ডার্ক ব্যাকগ্রাউন্ড

    camera = new THREE.PerspectiveCamera(60, zone.clientWidth / zone.clientHeight, 0.1, 1000);
    camera.position.set(0, 15, 25);

    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: "high-performance" });
    renderer.setSize(zone.clientWidth, zone.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    zone.appendChild(renderer.domElement);

    // লাইটিং (সিন সুন্দর করার জন্য)
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.0);
    scene.add(ambientLight);
    
    const sunLight = new THREE.DirectionalLight(0xffffff, 1.2);
    sunLight.position.set(20, 40, 20);
    sunLight.castShadow = true;
    scene.add(sunLight);

    // মেইন গ্রাউন্ড (মাটি)
    const groundGeo = new THREE.PlaneGeometry(200, 200);
    const groundMat = new THREE.MeshStandardMaterial({ color: 0x2c3e50, roughness: 0.8 });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI / 2;
    ground.receiveShadow = true;
    ground.name = "ground";
    scene.add(ground);

    // গ্রিড হেল্পার
    const grid = new THREE.GridHelper(200, 50, 0x3f4456, 0x282c37);
    grid.position.y = 0.01;
    scene.add(grid);

    loader = new THREE.GLTFLoader();

    // অল-ডিভাইস স্ক্রিন কন্ট্রোল (OrbitControls)
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
    controls.maxPolarAngle = Math.PI / 2 - 0.01;
}

// গিটহাব ফাইল আপলোড
document.getElementById('file-input').addEventListener('change', function(e) {
    const files = e.target.files;
    for(let file of files) {
        uploadedFiles.push(file.name);
        appendChat(file.name + " আপলোড হয়েছে!", "user");
        const url = URL.createObjectURL(file);
        loader.load(url, function(gltf) {
            const m = gltf.scene;
            m.position.set((Math.random()-0.5)*20, 0, (Math.random()-0.5)*20);
            scene.add(m);
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

// 🌍 ইউনিভার্সাল এআই ওয়ার্ল্ড প্রসেসর (ইউজার যা লিখবে, তা-ই স্ক্রিনে তৈরি হবে)
function processUserWorldCommand(prompt) {
    const cmd = prompt.toLowerCase();
    let statusMessage = "কমান্ড প্রসেস করা হয়েছে।";

    // ১. মাটির কালার পরিবর্তন (ঘাস, বালি, কাদা, পানি ইত্যাদি)
    const ground = scene.getObjectByName("ground");
    if (ground) {
        if (cmd.includes("ঘাস") || cmd.includes("grass") || cmd.includes("সবুজ")) {
            ground.material.color.setHex(0x27ae60);
            statusMessage = "মাঠের মাটি সবুজ ঘাসে রূপান্তর করা হয়েছে।";
        }
        if (cmd.includes("বালি") || cmd.includes("sand") || cmd.includes("মরুভূমি")) {
            ground.material.color.setHex(0xf1c40f);
            statusMessage = "মাঠের মাটি বালুকাময় মরুভূমিতে রূপান্তর করা হয়েছে।";
        }
        if (cmd.includes("পানি") || cmd.includes("water") || cmd.includes("নদী") || cmd.includes("সমুদ্র")) {
            ground.material.color.setHex(0x2980b9);
            statusMessage = "পুরো এলাকা পানিতে রূপান্তর করা হয়েছে।";
        }
        if (cmd.includes("কালো") || cmd.includes("dark")) {
            ground.material.color.setHex(0x111111);
        }
    }

    // ২. আকাশ বা ব্যাকগ্রাউন্ডের কালার পরিবর্তন
    if (cmd.includes("আকাশ") || cmd.includes("sky")) {
        if (cmd.includes("লাল") || cmd.includes("red")) scene.background = new THREE.Color(0x5c1d1d);
        if (cmd.includes("নীল") || cmd.includes("blue")) scene.background = new THREE.Color(0x3498db);
        if (cmd.includes("কালো") || cmd.includes("night")) scene.background = new THREE.Color(0x050508);
        if (cmd.includes("সাদা") || cmd.includes("white")) scene.background = new THREE.Color(0xffffff);
        statusMessage = "আকাশের আবহাওয়া এবং কালার স্কিম পরিবর্তন করা হয়েছে।";
    }

    // ৩. বাড়ি বা ঘর তৈরি (Building / House)
    if (cmd.includes("বাড়ি") || cmd.includes("ঘর") || cmd.includes("house") || cmd.includes("building")) {
        const count = extractNumber(cmd) || 1;
        for(let i=0; i<count; i++) {
            const house = new THREE.Group();
            // দেয়াল
            const bGeo = new THREE.BoxGeometry(4, 4, 4);
            const bMat = new THREE.MeshStandardMaterial({ color: 0xd2dae2, roughness: 0.5 });
            const body = new THREE.Mesh(bGeo, bMat);
            body.position.y = 2;
            house.add(body);
            // ছাদ
            const rGeo = new THREE.ConeGeometry(3.5, 2, 4);
            const rMat = new THREE.MeshStandardMaterial({ color: 0xff4757 });
            const roof = new THREE.Mesh(rGeo, rMat);
            roof.position.y = 5;
            roof.rotation.y = Math.PI / 4;
            house.add(roof);

            house.position.set((Math.random() - 0.5) * 40, 0, (Math.random() - 0.5) * 40);
            scene.add(house);
        }
        statusMessage = `${count}টি কাস্টম থ্রিডি স্ট্রাকচার/বাড়ি তৈরি করা হয়েছে।`;
    }

    // ৪. গাছপালা তৈরি (Trees)
    if (cmd.includes("গাছ") || cmd.includes("tree") || cmd.includes("বন")) {
        const count = extractNumber(cmd) || 3;
        for(let i=0; i<count; i++) {
            const tree = new THREE.Group();
            // গুড়ি
            const trunkGeo = new THREE.CylinderGeometry(0.3, 0.4, 3);
            const trunkMat = new THREE.MeshStandardMaterial({ color: 0x784c1d });
            const trunk = new THREE.Mesh(trunkGeo, trunkMat);
            trunk.position.y = 1.5;
            tree.add(trunk);
            // পাতা
            const leavesGeo = new THREE.SphereGeometry(1.5, 8, 8);
            const leavesMat = new THREE.MeshStandardMaterial({ color: 0x10ac84, roughness: 0.6 });
            const leaves = new THREE.Mesh(leavesGeo, leavesMat);
            leaves.position.y = 3.5;
            tree.add(leaves);

            tree.position.set((Math.random() - 0.5) * 50, 0, (Math.random() - 0.5) * 50);
            scene.add(tree);
        }
        statusMessage = `পরিবেশে ${count}টি রিয়েল-টাইম থ্রিডি গাছ যোগ করা হয়েছে।`;
    }

    // ৫. পাহাড় বা অবজেক্ট তৈরি (Mountains / Hills / Blocks)
    if (cmd.includes("পাহাড়") || cmd.includes("mountain") || cmd.includes("stone") || cmd.includes("পাথর")) {
        const count = extractNumber(cmd) || 1;
        for(let i=0; i<count; i++) {
            const geo = new THREE.ConeGeometry(8, 12, 5);
            const mat = new THREE.MeshStandardMaterial({ color: 0x57606f, roughness: 0.9 });
            const mountain = new THREE.Mesh(geo, mat);
            mountain.position.set((Math.random() - 0.5) * 60, 6, (Math.random() - 0.5) * 60);
            scene.add(mountain);
        }
        statusMessage = "ম্যাপে প্রাকৃতি পাহাড় এলিমেন্ট যুক্ত করা হয়েছে।";
    }

    // ৬. গাড়ি বা ক্যারেক্টার (Vehicles / Dynamic Shapes)
    if (cmd.includes("গাড়ি") || cmd.includes("car") || cmd.includes("vehicle")) {
        const car = new THREE.Group();
        const bodyGeo = new THREE.BoxGeometry(5, 1.5, 2.5);
        const bodyMat = new THREE.MeshStandardMaterial({ color: 0xff9f43 });
        const body = new THREE.Mesh(bodyGeo, bodyMat);
        body.position.y = 1;
        car.add(body);

        car.position.set((Math.random() - 0.5) * 20, 0, (Math.random() - 0.5) * 20);
        scene.add(car);
        statusMessage = "একটি থ্রিডি ভেহিকল চ্যাসিস স্পন করা হয়েছে।";
    }

    // ৭. যদি সাধারণ কোনো জ্যামিতিক অবজেক্ট বা নাম ছাড়া কিছু হয়
    if (statusMessage === "কমান্ড প্রসেস করা হয়েছে।" && !cmd.includes("sky") && !cmd.includes("আকাশ")) {
        const geometry = new THREE.BoxGeometry(3, 3, 3);
        const material = new THREE.MeshStandardMaterial({ color: Math.random() * 0xffffff });
        const obj = new THREE.Mesh(geometry, material);
        obj.position.set((Math.random() - 0.5) * 20, 1.5, (Math.random() - 0.5) * 20);
        scene.add(obj);
        statusMessage = `আপনার প্রম্পট রিড করে একটি কাস্টম থ্রিডি শেপ ('${prompt}') জেনারেট করা হয়েছে।`;
    }

    return statusMessage;
}

// টেক্সট থেকে সংখ্যা খুঁজে বের করার ছোট ফাংশন (যেমন: ৫টি বাড়ি বললে ৫টি তৈরি হবে)
function extractNumber(text) {
    const matches = text.match(/\d+/);
    return matches ? parseInt(matches[0]) : null;
}

async function sendToAI() {
    const prompt = document.getElementById('ai-prompt').value;
    const name = document.getElementById('game-name').value;
    const desc = document.getElementById('game-desc').value;

    if(!prompt) return alert("দয়া করে আপনি কী তৈরি করতে চান তা লিখুন!");

    appendChat(prompt, "user");
    document.getElementById('ai-prompt').value = "";
    document.getElementById('loading').style.display = "flex";

    // লোকাল ইঞ্জিন প্রম্পট রিড করে সাথে সাথে থ্রিডি ওয়ার্ল্ড আপডেট করবে
    const localVisualFeedback = processUserWorldCommand(prompt);

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
        appendChat("Ignite3D AI: " + localVisualFeedback, "ai");
    } catch (error) {
        appendChat("Ignite3D AI: " + localVisualFeedback + " (সার্ভার অফলাইন থাকলেও রেন্ডারিং সফল হয়েছে।)", "ai");
    } finally {
        document.getElementById('loading').style.display = "none";
    }
}

function downloadAPK() {
    if (!currentGameState.game_name) {
        return alert("প্রথমে গেম জেনারেট করুন!");
    }
    window.open(`${BACKEND_URL}/download-build?game=${currentGameState.game_name}`, '_blank');
}

window.onload = init3D;
