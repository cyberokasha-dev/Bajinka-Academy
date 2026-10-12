"""Version learner web entry assets so existing browser caches receive updates."""
import pathlib, re, sys
root = pathlib.Path('build/web')
if not (root / 'assets/assets/runner/marking.js').is_file():
    raise SystemExit('Missing runner comparison asset; cannot publish a broken checker.')
version = re.sub(r'[^a-zA-Z0-9]', '', sys.argv[1])[:16]
bootstrap = root / 'flutter_bootstrap.js'
s = bootstrap.read_text()
s = s.replace('"mainJsPath":"main.dart.js"', f'"mainJsPath":"main.dart.js?build={version}"')
s = re.sub(r'_flutter\.loader\.load\(\{\s*serviceWorkerSettings:[\s\S]*?\}\s*\}\);', '_flutter.loader.load();', s)
# Retire this app's deprecated Flutter worker; local learning storage is untouched.
s = "if ('serviceWorker' in navigator) navigator.serviceWorker.getRegistrations().then(rs => rs.filter(r => r.scope === new URL('./', location.href).href.split('?')[0]).forEach(r => r.unregister()));\n" + s
bootstrap.write_text(s)
index = root / 'index.html'
s = index.read_text().replace('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?build={version}"')
s = s.replace('<title>bajinka_academy</title>', '<title>Bajinka Academy</title>').replace('A new Flutter project.', 'Learn Python with lessons, practice, notes and saved learning progress.').replace('content="bajinka_academy"', 'content="Bajinka Academy"')
index.write_text(s)
print('Versioned learner web assets:', version)
