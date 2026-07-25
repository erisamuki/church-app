const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'gracehub',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

async function seed() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Create Church
    const churchRes = await client.query(`
      INSERT INTO churches (name, slug, denomination, address, city, state, phone, email)
      VALUES ('Grace Community Church', 'grace-community', 'Non-Denominational', '123 Faith Street', 'Springfield', 'IL', '+1-555-0100', 'info@gracecommunity.church')
      RETURNING id
    `);
    const churchId = churchRes.rows[0].id;
    console.log('Created church:', churchId);

    // 2. Create Admin User
    const hashedPassword = await bcrypt.hash('admin123', 12);
    const userRes = await client.query(`
      INSERT INTO users (church_id, email, password_hash, first_name, last_name, phone, role)
      VALUES ($1, 'pastor@gracehub.app', $2, 'Samuel', 'Johnson', '+1-555-0101', 'admin')
      RETURNING id
    `, [churchId, hashedPassword]);
    console.log('Created admin user:', userRes.rows[0].id);

    // 3. Create Members
    const members = [
      ['John', 'Davis', 'john.davis@email.com', '+1-555-0201', 'member', '2023-01-15'],
      ['Maria', 'Rodriguez', 'maria.r@email.com', '+1-555-0202', 'member', '2023-02-20'],
      ['Kevin', 'Thompson', 'kevin.t@email.com', '+1-555-0203', 'active', '2024-03-10'],
      ['Sarah', 'Williams', 'sarah.w@email.com', '+1-555-0204', 'active', '2024-01-05'],
      ['David', 'Chen', 'david.c@email.com', '+1-555-0205', 'member', '2023-06-12'],
      ['Emily', 'Johnson', 'emily.j@email.com', '+1-555-0206', 'visitor', null],
      ['Michael', 'Brown', 'mike.b@email.com', '+1-555-0207', 'active', '2024-05-18'],
      ['Jessica', 'Lee', 'jessica.l@email.com', '+1-555-0208', 'member', '2023-09-22'],
      ['Robert', 'Taylor', 'rob.t@email.com', '+1-555-0209', 'inactive', '2022-11-30'],
      ['Amanda', 'White', 'amanda.w@email.com', '+1-555-0210', 'active', '2024-07-01'],
    ];

    const memberIds = [];
    for (const m of members) {
      const res = await client.query(`
        INSERT INTO members (church_id, first_name, last_name, email, phone, membership_status, membership_date)
        VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id
      `, [churchId, ...m]);
      memberIds.push(res.rows[0].id);
    }
    console.log('Created', members.length, 'members');

    // 4. Create Small Groups
    const groupRes = await client.query(`
      INSERT INTO small_groups (church_id, name, description, group_type, leader_id, meeting_day, meeting_time, meeting_location)
      VALUES 
        ($1, 'Young Adults Bible Study', 'Weekly study for ages 18-30', 'small_group', $2, 'Wednesday', '19:00:00', 'Room 201'),
        ($1, 'Women''s Prayer Circle', 'Monthly prayer gathering', 'small_group', $3, 'Tuesday', '10:00:00', 'Fellowship Hall'),
        ($1, 'Youth Ministry', 'Friday night youth group', 'youth', $4, 'Friday', '18:30:00', 'Youth Center'),
        ($1, 'Outreach Team', 'Community service and evangelism', 'outreach', $5, 'Saturday', '08:00:00', 'Church Parking Lot')
      RETURNING id
    `, [churchId, memberIds[0], memberIds[1], memberIds[2], memberIds[3]]);
    console.log('Created', groupRes.rows.length, 'groups');

    // 5. Add members to groups
    await client.query(`
      INSERT INTO group_members (group_id, member_id, role)
      VALUES 
        ((SELECT id FROM small_groups WHERE name = 'Young Adults Bible Study'), $1, 'leader'),
        ((SELECT id FROM small_groups WHERE name = 'Young Adults Bible Study'), $2, 'member'),
        ((SELECT id FROM small_groups WHERE name = 'Young Adults Bible Study'), $3, 'member'),
        ((SELECT id FROM small_groups WHERE name = 'Women''s Prayer Circle'), $4, 'leader'),
        ((SELECT id FROM small_groups WHERE name = 'Women''s Prayer Circle'), $5, 'member'),
        ((SELECT id FROM small_groups WHERE name = 'Youth Ministry'), $6, 'leader'),
        ((SELECT id FROM small_groups WHERE name = 'Outreach Team'), $7, 'leader')
    `, [memberIds[0], memberIds[3], memberIds[5], memberIds[1], memberIds[6], memberIds[2], memberIds[3]]);

    // 6. Create Events
    const now = new Date();
    const events = [
      ['Sunday Worship Service', 'service', new Date(now.getFullYear(), now.getMonth(), now.getDate() + (7 - now.getDay()) % 7, 9, 0), 'Main Sanctuary', 500],
      ['Wednesday Bible Study', 'bible_study', new Date(now.getFullYear(), now.getMonth(), now.getDate() + (3 - now.getDay() + 7) % 7, 19, 0), 'Room 201', 50],
      ['Community Outreach', 'outreach', new Date(now.getFullYear(), now.getMonth(), now.getDate() + (6 - now.getDay() + 7) % 7, 8, 0), 'Downtown Park', 100],
      ['Youth Night', 'social', new Date(now.getFullYear(), now.getMonth(), now.getDate() + (5 - now.getDay() + 7) % 7, 18, 30), 'Youth Center', 80],
      ['Prayer Vigil', 'prayer', new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 20, 0), 'Prayer Room', 30],
    ];

    for (const e of events) {
      await client.query(`
        INSERT INTO events (church_id, title, event_type, start_datetime, location, max_attendees, status, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, 'published', (SELECT id FROM users LIMIT 1))
      `, [churchId, ...e]);
    }
    console.log('Created', events.length, 'events');

    // 7. Create Giving Categories
    const categories = [
      ['General Fund', 'General church operations', true, 50000, '#3B82F6'],
      ['Building Fund', 'New sanctuary construction', true, 100000, '#10B981'],
      ['Missions', 'Missionary support', true, 15000, '#8B5CF6'],
      ['Youth Ministry', 'Youth programs and activities', true, 8000, '#F59E0B'],
      ['Food Pantry', 'Community food assistance', true, 5000, '#EF4444'],
    ];

    for (const c of categories) {
      await client.query(`
        INSERT INTO giving_categories (church_id, name, description, is_tax_deductible, goal_amount, color)
        VALUES ($1, $2, $3, $4, $5, $6)
      `, [churchId, ...c]);
    }
    console.log('Created', categories.length, 'giving categories');

    // 8. Create Donations
    const donationAmounts = [250, 100, 500, 75, 1000, 50, 200, 150, 300, 80];
    const methods = ['online', 'check', 'cash', 'credit_card', 'bank_transfer'];

    for (let i = 0; i < 50; i++) {
      const memberId = memberIds[i % memberIds.length];
      const amount = donationAmounts[i % donationAmounts.length] * (Math.random() * 2 + 0.5);
      const method = methods[i % methods.length];
      const date = new Date(now.getFullYear(), now.getMonth() - (i % 12), 1 + (i % 28));

      await client.query(`
        INSERT INTO donations (church_id, member_id, category_id, amount, payment_method, donation_date)
        VALUES ($1, $2, (SELECT id FROM giving_categories ORDER BY random() LIMIT 1), $3, $4, $5)
      `, [churchId, memberId, amount.toFixed(2), method, date.toISOString().split('T')[0]]);
    }
    console.log('Created 50 donations');

    // 9. Create Volunteer Roles
    const roles = [
      ['Usher', 'Greet and seat attendees', 'Worship', '#3B82F6'],
      ['Worship Team', 'Lead music and worship', 'Worship', '#8B5CF6'],
      ['Sound Tech', 'Audio mixing and equipment', 'Technical', '#10B981'],
      ["Children's Teacher", 'Sunday school instruction', 'Education', '#F59E0B'],
      ['Greeter', 'Welcome visitors at entrance', 'Hospitality', '#EC4899'],
      ['Parking Attendant', 'Direct parking traffic', 'Operations', '#64748B'],
    ];

    for (const r of roles) {
      await client.query(`
        INSERT INTO volunteer_roles (church_id, name, description, department, color)
        VALUES ($1, $2, $3, $4, $5)
      `, [churchId, ...r]);
    }
    console.log('Created', roles.length, 'volunteer roles');

    // 10. Create Announcements
    const announcements = [
      ['Welcome New Members!', 'We are excited to welcome 5 new families this month. Join us for a welcome lunch after service.', 'general', 'normal', 'all'],
      ['Building Fund Update', 'We have reached 60% of our goal! Thank you for your generous contributions.', 'general', 'normal', 'all'],
      ['Youth Camp Registration', 'Summer camp registration is now open. Early bird pricing ends July 30.', 'youth', 'high', 'youth'],
      ['Volunteer Appreciation Dinner', 'Join us August 15th to celebrate our amazing volunteers.', 'general', 'normal', 'volunteers'],
    ];

    for (const a of announcements) {
      await client.query(`
        INSERT INTO announcements (church_id, title, content, category, priority, target_audience, status, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, 'published', (SELECT id FROM users LIMIT 1))
      `, [churchId, ...a]);
    }
    console.log('Created', announcements.length, 'announcements');

    // 11. Create Sermon Series & Sermons
    const seriesRes = await client.query(`
      INSERT INTO sermon_series (church_id, title, description, speaker, start_date)
      VALUES ($1, 'Walking in Faith', 'A 6-week series on living by faith', 'Pastor Samuel Johnson', '2024-06-01')
      RETURNING id
    `, [churchId]);
    const seriesId = seriesRes.rows[0].id;

    const sermons = [
      ['Faith Over Fear', 'Hebrews 11:1-6', '2024-06-02', 2400],
      ['Faith in Action', 'James 2:14-26', '2024-06-09', 2100],
      ['Faith Through Trials', '1 Peter 1:3-9', '2024-06-16', 2300],
      ['Faith That Moves Mountains', 'Matthew 17:20', '2024-06-23', 2500],
    ];

    for (const s of sermons) {
      await client.query(`
        INSERT INTO sermons (church_id, series_id, title, speaker, scripture_reference, preached_date, duration_seconds, created_by)
        VALUES ($1, $2, $3, 'Pastor Samuel Johnson', $4, $5, $6, (SELECT id FROM users LIMIT 1))
      `, [churchId, seriesId, ...s]);
    }
    console.log('Created sermon series with', sermons.length, 'sermons');

    await client.query('COMMIT');
    console.log('\n Seed completed successfully!');
    console.log('\n Login credentials:');
    console.log('  Email: pastor@gracehub.app');
    console.log('  Password: admin123');
    console.log('  Church ID:', churchId);

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

seed().catch(console.error);