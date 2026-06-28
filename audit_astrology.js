const fs = require('fs');
const path = require('path');
const root = 'D:\\code\\slaytheword\\slayword';

function safeParseJson(filePath) {
    let raw = fs.readFileSync(filePath, 'utf8');
    // Replace common control characters that break JSON parsers
    // \x00-\x1f except \n \r \t
    raw = raw.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f]/g, '');
    return JSON.parse(raw);
}

function auditCards() {
    const cardsDir = path.join(root, 'external', 'data', 'cards');
    const files = fs.readdirSync(cardsDir).filter(f => f.startsWith('card_astrology_') && f.endsWith('.json'));
    const issues = [];

    for (const f of files) {
        const fp = path.join(cardsDir, f);
        let json;
        try {
            json = safeParseJson(fp);
        } catch(e) {
            issues.push({file: f, issue: 'JSON_PARSE_ERROR', details: e.message.substring(0, 120)});
            continue;
        }
        const p = json.properties || {};
        
        if (p.card_appears_in_card_packs === true) {
            const vals = p.card_values || {};
            for (const k of Object.keys(vals)) {
                if (k === 'bonus_damage' || k === 'bonus_block') {
                    issues.push({file: f, issue: 'HAS_BONUS_KEY', details: 'card_values contains ' + k});
                }
            }
            const desc = p.card_description || '';
            if (/\[bonus_damage\]/.test(desc)) {
                issues.push({file: f, issue: 'DESC_HAS_[bonus_damage]', details: 'desc: ' + desc.substring(0, 150)});
            }
            if (/\[bonus_block\]/.test(desc)) {
                issues.push({file: f, issue: 'DESC_HAS_[bonus_block]', details: 'desc: ' + desc.substring(0, 150)});
            }
        }
        
        function checkActions(actions, context) {
            if (!Array.isArray(actions)) return;
            for (const action of actions) {
                if (typeof action !== 'object' || action === null) continue;
                for (const key of Object.keys(action)) {
                    if (key.startsWith('res://')) {
                        const diskPath = path.join(root, key.replace('res://', ''));
                        if (!fs.existsSync(diskPath)) {
                            issues.push({file: f, issue: 'SCRIPT_MISSING (' + context + ')', details: key});
                        }
                    }
                    const val = action[key];
                    if (val && typeof val === 'object' && !Array.isArray(val)) {
                        if (Array.isArray(val.action_data)) {
                            checkActions(val.action_data, context + '/action_data');
                        }
                        if (Array.isArray(val.actions_on_lethal)) {
                            checkActions(val.actions_on_lethal, context + '/actions_on_lethal');
                        }
                    }
                }
            }
        }

        const actionFields = [
            'card_play_actions', 'card_discard_actions', 'card_end_of_turn_actions',
            'card_exhaust_actions', 'card_draw_actions', 'card_retain_actions',
            'card_right_click_actions', 'card_initial_combat_actions',
            'card_add_to_deck_actions', 'card_remove_from_deck_actions',
            'card_transform_in_deck_actions', 'card_play_validators',
            'card_glow_validators', 'card_listeners'
        ];
        for (const field of actionFields) {
            checkActions(p[field], field);
        }
    }
    return issues;
}

function auditArtifactsAndConsumables() {
    const issues = [];
    const dirs = [
        path.join(root, 'external', 'data', 'artifacts'),
        path.join(root, 'external', 'data', 'consumables')
    ];

    for (const dir of dirs) {
        if (!fs.existsSync(dir)) continue;
        const files = fs.readdirSync(dir).filter(f => f.endsWith('.json'));
        for (const f of files) {
            const fp = path.join(dir, f);
            let json;
            try {
                json = safeParseJson(fp);
            } catch(e) {
                issues.push({file: f, issue: 'JSON_PARSE_ERROR', details: e.message.substring(0, 120)});
                continue;
            }

            function findScriptRefs(obj, context) {
                if (typeof obj === 'string') {
                    if (obj.startsWith('res://')) {
                        const diskPath = path.join(root, obj.replace('res://', ''));
                        if (!fs.existsSync(diskPath)) {
                            issues.push({file: f, issue: 'SCRIPT_MISSING (' + context + ')', details: obj});
                        }
                    }
                    return;
                }
                if (Array.isArray(obj)) {
                    for (let i = 0; i < obj.length; i++) {
                        findScriptRefs(obj[i], context + '[' + i + ']');
                    }
                    return;
                }
                if (obj && typeof obj === 'object') {
                    for (const key of Object.keys(obj)) {
                        findScriptRefs(obj[key], context + '.' + key);
                    }
                }
            }
            
            const props = json.properties || json;
            findScriptRefs(props, 'properties');
        }
    }
    return issues;
}

const cardIssues = auditCards();
const artifactConsumableIssues = auditArtifactsAndConsumables();
const allIssues = [...cardIssues, ...artifactConsumableIssues];

if (allIssues.length === 0) {
    console.log('No issues found.');
} else {
    console.log('| File | Issue | Details |');
    console.log('|------|-------|---------|');
    for (const i of allIssues) {
        const details = i.details.replace(/\|/g, '\\|').replace(/\n/g, ' ');
        console.log('| ' + i.file + ' | ' + i.issue + ' | ' + details + ' |');
    }
}
