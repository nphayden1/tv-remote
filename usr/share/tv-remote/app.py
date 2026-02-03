import os
import subprocess
import re
from flask import Flask, render_template_string, request, jsonify

app = Flask(__name__)

CHANNELS = {
    "Atlas Survival Shelters": "@AtlasSurvivalShelters",
    "Billy Yang": "@BillyYang",
    "Black Rifle Coffee Company": "@BlackRifleCoffeeCompany",
    "Brandon Herrera": "@BrandonHerrera",
    "Clay Hayes": "@ClayHayesHunter",
    "Cowboy Kent Rollins": "@CowboyKentRollins",
    "Garand Thumb": "@GarandThumb",
    "Holdfast Alaska": "@HoldfastAlaska",
    "Kentucky Ballistics": "@KentuckyBallistics",
    "Life on the Moose": "@LifeontheMoose",
    "Liz Hayes": "@LizHayes",
    "LockPicking Lawyer": "@lockpickinglawyer",
    "Shug Emery": "@shugemery",
    "Simple Living Alaska": "@SimpleLivingAlaska",
    "The OffGrid Hermit": "@TheOffGridHermit",
    "Tim Farmer": "@TimFarmersCountryKitchen"
}

SCRIPT_PATH = os.path.join("/usr/share/tv-remote/", "actions.sh")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>TV Remote</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: sans-serif; text-align: center; background: #000; color: #fff; padding: 20px; }
        .container { max-width: 450px; margin: auto; background: #1a1a1a; padding: 25px; border-radius: 20px; border: 1px solid #333; }
        select, button { width: 100%; padding: 18px; margin: 10px 0; border-radius: 12px; font-size: 1.1rem; border: none; }
        select { background: #333; color: white; }
        .btn-go { background: #e60000; color: white; font-weight: bold; cursor: pointer; }
        .btn-pause { background: #007bff; color: white; font-weight: bold; cursor: pointer; }
        .slider-container { margin: 30px 0; }
        label { display: block; margin-bottom: 10px; font-weight: bold; color: #aaa; }
        input[type=range] { width: 100%; height: 15px; border-radius: 5px; background: #444; outline: none; -webkit-appearance: none; }
        input[type=range]::-webkit-slider-thumb { -webkit-appearance: none; width: 30px; height: 30px; border-radius: 50%; background: #ff0000; cursor: pointer; border: 2px solid white; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📺 TV Remote</h1>
        <select id="channelSelect" onchange="updateVideos()">
            <option value="">-- Choose Channel --</option>
            {% for name, handle in channels.items() %}
                <option value="{{ handle }}">{{ name }}</option>
            {% endfor %}
        </select>
        <select id="videoSelect"><option value="">-- No Videos --</option></select>
        <button class="btn-go" onclick="runAction('open_video')">🚀 LAUNCH ON TV</button>
        
        <div class="slider-container">
            <label>🔊 VOLUME</label>
            <input type="range" min="0" max="100" value="70" oninput="setVolume(this.value)">
        </div>

        <hr style="border:0; border-top:1px solid #333; margin:20px 0;">
        <button class="btn-pause" onclick="runAction('toggle')">⏯️ PLAY / PAUSE</button>
    </div>
    <script>
        function updateVideos() {
            var handle = document.getElementById('channelSelect').value;
            var videoSelect = document.getElementById('videoSelect');
            if (!handle) return;
            videoSelect.innerHTML = '<option>Loading...</option>';
            fetch('/get_videos/' + handle)
                .then(res => res.json())
                .then(data => {
                    videoSelect.innerHTML = '';
                    data.forEach(v => {
                        var opt = document.createElement('option');
                        opt.value = v.url; opt.innerHTML = v.title;
                        videoSelect.appendChild(opt);
                    });
                });
        }
        function setVolume(val) {
            fetch('/volume', { method: 'POST', body: new URLSearchParams({level: val}) });
        }
        function runAction(act) {
            var url = document.getElementById('videoSelect').value;
            var fd = new FormData();
            fd.append('action', act);
            fd.append('url', url);
            fetch('/run', { method: 'POST', body: fd });
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE, channels=dict(sorted(CHANNELS.items())))

@app.route('/get_videos/<handle>')
def get_videos(handle):
    try:
        url = f"https://www.youtube.com/{handle}/videos"
        # Using curl to fetch the page with a browser identity
        cmd = ["curl", "-sL", "-A", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", url]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # This refined regex looks for the specific "videoRenderer" JSON block 
        # that identifies actual video uploads in the grid.
        pattern = r'videoRenderer":\{"videoId":"(.*?)".*?"title":\{"runs":\[\{"text":"(.*?)"\}\]'
        matches = re.findall(pattern, result.stdout)
        
        videos = []
        seen = set()
        for vid_id, title in matches:
            if vid_id not in seen:
                # Basic cleanup of common HTML/JSON entities
                title = title.replace('\\u0026', '&').replace('\\"', '"')
                videos.append({"title": title, "url": f"https://www.youtube.com/watch?v={vid_id}"})
                seen.add(vid_id)
        
        return jsonify(videos[:10])
    except:
        return jsonify([])

@app.route('/volume', methods=['POST'])
def volume():
    level = request.form.get('level', '70')
    # Use SCRIPT_PATH so it runs through actions.sh
    subprocess.run([SCRIPT_PATH, "volume", level])
    return "OK"

@app.route('/run', methods=['POST'])
def run():
    action, url = request.form.get('action'), request.form.get('url', '')
    subprocess.run([SCRIPT_PATH, action, url])
    return "OK"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
