const fs = require('fs');
const path = require('path');

const publicDir = path.join(__dirname, 'public');
const files = fs.readdirSync(publicDir).filter(f => f.endsWith('.html') && f !== 'stores.html' && f !== 'login.html');

const targetText = `                <a href="/ads" class="menu-item">
                    <span class="material-icons-round">ad_units</span>
                    Banners (Ads)
                </a>`;

const insertText = `                <a href="/stores" class="menu-item">
                    <span class="material-icons-round">storefront</span>
                    Cửa hàng
                </a>
                <a href="/ads" class="menu-item">
                    <span class="material-icons-round">ad_units</span>
                    Banners (Ads)
                </a>`;

files.forEach(file => {
    const filePath = path.join(publicDir, file);
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Some files might have different indentation or spacing, so a regex is safer,
    // but a direct replace should work if they are consistent.
    
    // Instead of exact string matching, let's use a regex to find the /ads link
    const regex = /(\s*<a href="\/ads" class="menu-item">.*?<\/a>\s*)/s;
    
    if (content.includes('href="/stores"')) {
        console.log(`Skipping ${file}, already has stores link.`);
        return;
    }
    
    if (content.match(regex)) {
        content = content.replace(regex, `
                <a href="/stores" class="menu-item">
                    <span class="material-icons-round">storefront</span>
                    Cửa hàng
                </a>$1`);
        fs.writeFileSync(filePath, content);
        console.log(`Updated ${file}`);
    } else {
        console.log(`Warning: Could not find anchor tag in ${file}`);
    }
});
