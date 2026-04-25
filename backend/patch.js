const { execSync } = require('child_process');
try {
  execSync(`vercel api /v9/projects/prj_8StWPcq5cPci4sGQDh1DR8rGqzPU?teamId=team_m6R0mLuDovWSwQaCfll5OXg8 -X PATCH -d "{\\"ssoProtection\\":null}"`, { stdio: 'inherit' });
  console.log("Success!");
} catch (e) {
  console.error("Failed");
}
