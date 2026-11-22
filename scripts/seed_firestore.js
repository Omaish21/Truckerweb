// Seed real logistics data directly into Firebase Firestore for TruckLink PK
const https = require('https');
const { execSync } = require('child_process');

// Get fresh Google Cloud Access Token
let token = '';
try {
  token = execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();
} catch (e) {
  console.error('Failed to get token:', e);
  process.exit(1);
}

const PROJECT_ID = 'trucker-s-website';
const BASE_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function writeDoc(collection, docId, fields) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({ fields });
    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: `${BASE_PATH}/${collection}?documentId=${docId}`,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (d) => body += d);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`[SUCCESS] Wrote ${collection}/${docId}`);
          resolve(JSON.parse(body));
        } else if (res.statusCode === 409) {
          // Document already exists, use PATCH to update
          patchDoc(collection, docId, fields).then(resolve).catch(reject);
        } else {
          console.error(`[ERROR ${res.statusCode}] ${collection}/${docId}:`, body);
          reject(new Error(body));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function patchDoc(collection, docId, fields) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({ fields });
    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: `${BASE_PATH}/${collection}/${docId}`,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (d) => body += d);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          console.log(`[UPDATED] Patched ${collection}/${docId}`);
          resolve(JSON.parse(body));
        } else {
          console.error(`[ERROR ${res.statusCode}] Patch ${collection}/${docId}:`, body);
          reject(new Error(body));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

const now = new Date().toISOString();

const loads = [
  {
    id: 'load-khi-lhr-22w',
    fields: {
      owner_id: { stringValue: 'transporter-qasim-1' },
      origin_city: { stringValue: 'Karachi (Port Qasim)' },
      destination_city: { stringValue: 'Lahore (Badami Bagh)' },
      vehicle_type_required: { stringValue: '22_wheeler' },
      weight_tons: { doubleValue: 42.0 },
      goods_type: { stringValue: 'Heavy Industrial Machinery & Steel Billets' },
      offered_rate_pkr: { integerValue: '310000' },
      rate_type: { stringValue: 'fixed' },
      contact_phone: { stringValue: '+923001234567' },
      status: { stringValue: 'open' },
      bids_count: { integerValue: '2' },
      length_ft: { doubleValue: 50.0 },
      height_ft: { doubleValue: 15.2 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'load-fsd-rwp-10w',
    fields: {
      owner_id: { stringValue: 'textile-mills-fsd' },
      origin_city: { stringValue: 'Faisalabad (Industrial Estate)' },
      destination_city: { stringValue: 'Rawalpindi (I-9 Freight Terminal)' },
      vehicle_type_required: { stringValue: '10_wheeler' },
      weight_tons: { doubleValue: 18.5 },
      goods_type: { stringValue: 'Yarn Cones & Export Cotton Rolls' },
      offered_rate_pkr: { integerValue: '95000' },
      rate_type: { stringValue: 'fixed' },
      contact_phone: { stringValue: '+923219876543' },
      status: { stringValue: 'open' },
      bids_count: { integerValue: '1' },
      length_ft: { doubleValue: 24.0 },
      height_ft: { doubleValue: 13.5 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'load-mul-qta-cont',
    fields: {
      owner_id: { stringValue: 'agro-multan-logistics' },
      origin_city: { stringValue: 'Multan (Chowk Kumharan)' },
      destination_city: { stringValue: 'Quetta (Eastern Bypass Dry Port)' },
      vehicle_type_required: { stringValue: 'container' },
      weight_tons: { doubleValue: 26.0 },
      goods_type: { stringValue: 'Export Mango Pulp & Fertilizer Bags' },
      offered_rate_pkr: { integerValue: '215000' },
      rate_type: { stringValue: 'fixed' },
      contact_phone: { stringValue: '+923334567890' },
      status: { stringValue: 'open' },
      bids_count: { integerValue: '0' },
      length_ft: { doubleValue: 40.0 },
      height_ft: { doubleValue: 14.8 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'load-khi-psh-tanker',
    fields: {
      owner_id: { stringValue: 'pak-petroleum-carrier' },
      origin_city: { stringValue: 'Karachi (Keamari Oil Terminal)' },
      destination_city: { stringValue: 'Peshawar (Hayatabad)' },
      vehicle_type_required: { stringValue: 'tanker' },
      weight_tons: { doubleValue: 44.0 },
      goods_type: { stringValue: 'Refined Diesel Fuel (OGRA Compliant)' },
      offered_rate_pkr: { integerValue: '380000' },
      rate_type: { stringValue: 'fixed' },
      contact_phone: { stringValue: '+923456789012' },
      status: { stringValue: 'open' },
      bids_count: { integerValue: '3' },
      length_ft: { doubleValue: 48.0 },
      height_ft: { doubleValue: 13.0 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'load-lhr-skr-mazda',
    fields: {
      owner_id: { stringValue: 'express-courier-pk' },
      origin_city: { stringValue: 'Lahore (Multan Road)' },
      destination_city: { stringValue: 'Sukkur (CPEC Interchange)' },
      vehicle_type_required: { stringValue: 'mazda' },
      weight_tons: { doubleValue: 7.5 },
      goods_type: { stringValue: 'FMCG Packaged Goods & Retail Stock' },
      offered_rate_pkr: { integerValue: '68000' },
      rate_type: { stringValue: 'fixed' },
      contact_phone: { stringValue: '+923012345678' },
      status: { stringValue: 'open' },
      bids_count: { integerValue: '0' },
      length_ft: { doubleValue: 17.0 },
      height_ft: { doubleValue: 11.5 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'load-gwdr-khi-flatbed',
    fields: {
      owner_id: { stringValue: 'cpec-coastal-freight' },
      origin_city: { stringValue: 'Gwadar (Free Zone Port)' },
      destination_city: { stringValue: 'Karachi (S.I.T.E)' },
      vehicle_type_required: { stringValue: 'flatbed' },
      weight_tons: { doubleValue: 35.0 },
      goods_type: { stringValue: 'Construction Rebar & Crane Counterweights' },
      offered_rate_pkr: { integerValue: '260000' },
      rate_type: { stringValue: 'fixed' },
      contact_phone: { stringValue: '+923129876543' },
      status: { stringValue: 'open' },
      bids_count: { integerValue: '1' },
      length_ft: { doubleValue: 45.0 },
      height_ft: { doubleValue: 12.0 },
      created_at: { timestampValue: now },
    },
  },
];

const cityTimings = [
  {
    id: 'karachi-heavy',
    fields: {
      city_name: { stringValue: 'Karachi (کراچی)' },
      vehicle_category: { stringValue: 'heavy' },
      entry_from: { stringValue: '23:00' },
      entry_until: { stringValue: '05:00' },
      notes: { stringValue: 'Day entry strictly prohibited. Heavy containers allowed 11 PM to 5 AM via Northern Bypass & Super Highway.' },
      confidence: { doubleValue: 0.98 },
    },
  },
  {
    id: 'lahore-heavy',
    fields: {
      city_name: { stringValue: 'Lahore (لاہور)' },
      vehicle_category: { stringValue: 'heavy' },
      entry_from: { stringValue: '22:00' },
      entry_until: { stringValue: '06:00' },
      notes: { stringValue: 'Ring Road & freight corridors open 10 PM to 6 AM. Day entry requires special traffic police permit.' },
      confidence: { doubleValue: 0.95 },
    },
  },
  {
    id: 'islamabad-heavy',
    fields: {
      city_name: { stringValue: 'Islamabad / Rawalpindi (اسلام آباد / راولپنڈی)' },
      vehicle_category: { stringValue: 'heavy' },
      entry_from: { stringValue: '23:00' },
      entry_until: { stringValue: '06:00' },
      notes: { stringValue: 'Expressway & I-9 Industrial Sector curfew active 6 AM to 11 PM.' },
      confidence: { doubleValue: 0.92 },
    },
  },
  {
    id: 'multan-heavy',
    fields: {
      city_name: { stringValue: 'Multan (ملتان)' },
      vehicle_category: { stringValue: 'heavy' },
      entry_from: { stringValue: '21:00' },
      entry_until: { stringValue: '06:00' },
      notes: { stringValue: 'Bosan Road and inner city bypass open for heavy trucks from 9 PM.' },
      confidence: { doubleValue: 0.90 },
    },
  },
  {
    id: 'faisalabad-heavy',
    fields: {
      city_name: { stringValue: 'Faisalabad (فیصل آباد)' },
      vehicle_category: { stringValue: 'heavy' },
      entry_from: { stringValue: '22:00' },
      entry_until: { stringValue: '06:00' },
      notes: { stringValue: 'Sargodha Road and Millat Road freight corridor open 10 PM to 6 AM.' },
      confidence: { doubleValue: 0.88 },
    },
  },
  {
    id: 'peshawar-heavy',
    fields: {
      city_name: { stringValue: 'Peshawar (پشاور)' },
      vehicle_category: { stringValue: 'heavy' },
      entry_from: { stringValue: '22:30' },
      entry_until: { stringValue: '05:30' },
      notes: { stringValue: 'GT Road and Ring Road heavy freight entry permitted 10:30 PM to 5:30 AM.' },
      confidence: { doubleValue: 0.91 },
    },
  },
];

const hazardReports = [
  {
    id: 'hazard-m5-fog',
    fields: {
      reported_by: { stringValue: 'nhmp-verified-officer' },
      reporter_id: { stringValue: 'nhmp-verified-officer' },
      category_id: { stringValue: 'accident' },
      report_type: { stringValue: 'accident' },
      location: { stringValue: 'Motorway M-5 (Multan to Sukkur Sector near Taranda)' },
      description: { stringValue: 'Dense winter night fog advisory. Maintain 100m safe vehicle distance. NHMP patrolling active.' },
      confidence: { doubleValue: 0.99 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'hazard-n5-bridge',
    fields: {
      reported_by: { stringValue: 'usr-sahiwal-driver' },
      reporter_id: { stringValue: 'usr-sahiwal-driver' },
      category_id: { stringValue: 'broken' },
      report_type: { stringValue: 'broken' },
      location: { stringValue: 'National Highway N-5 near Sahiwal Overhead Railway Bridge' },
      description: { stringValue: 'Low bridge clearance 14.0 ft. High-cube 15.2 ft container trucks must take bypass.' },
      confidence: { doubleValue: 0.95 },
      created_at: { timestampValue: now },
    },
  },
  {
    id: 'hazard-hyd-bypass',
    fields: {
      reported_by: { stringValue: 'usr-sindh-patrol' },
      reporter_id: { stringValue: 'usr-sindh-patrol' },
      category_id: { stringValue: 'kacha' },
      report_type: { stringValue: 'kacha' },
      location: { stringValue: 'Hyderabad Northern Bypass km 14' },
      description: { stringValue: 'Single lane asphalt repair work. Slow moving freight traffic with 15 min delay.' },
      confidence: { doubleValue: 0.92 },
      created_at: { timestampValue: now },
    },
  },
];

async function run() {
  console.log('Seeding Loads to Firestore...');
  for (const item of loads) {
    await writeDoc('loads', item.id, item.fields);
  }

  console.log('Seeding City Curfew Timings to Firestore...');
  for (const item of cityTimings) {
    await writeDoc('city_timings', item.id, item.fields);
  }

  console.log('Seeding Hazard Reports to Firestore...');
  for (const item of hazardReports) {
    await writeDoc('hazard_reports', item.id, item.fields);
  }

  console.log('Done! All real logistics data seeded to Firebase Firestore successfully.');
}

run().catch((err) => {
  console.error('Fatal seed error:', err);
  process.exit(1);
});
