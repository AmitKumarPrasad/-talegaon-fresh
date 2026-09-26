# Talegaon Fresh

Static customer-facing website for Talegaon Fresh, a local fruits and vegetables delivery business.

## Stack

- React
- Vite
- Bootstrap 5
- Bootstrap Icons

## Local development

```bash
npm install
npm run dev
```

## Production build

```bash
npm run build
npm run preview
```

## WhatsApp setup

Before production, replace `WHATSAPP_NUMBER` in `src/App.jsx` with the Talegaon Fresh WhatsApp Business number in international format without `+`.

The site intentionally does not display fixed product prices. Product buttons open WhatsApp and ask for today's price and availability.

## Netlify

Build command: `npm run build`

Publish directory: `dist`
