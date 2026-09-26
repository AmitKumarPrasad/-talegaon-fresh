import { useMemo, useState } from 'react';
import { categories, products } from './data/products';

const WHATSAPP_NUMBER = '919999999999'; // Replace with the Talegaon Fresh business number before launch.

function whatsappUrl(product = null) {
  const message = product
    ? `Hi Talegaon Fresh, I'd like to order ${product.name} – ${product.unit}. Please share today's price and availability.`
    : 'Hi Talegaon Fresh, I would like to see today\'s fresh fruits and vegetables catalogue.';
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`;
}

function Header() {
  return <header className="site-header sticky-top">
    <nav className="container navbar navbar-expand-lg py-3">
      <a className="navbar-brand d-flex align-items-center" href="#home" aria-label="Talegaon Fresh home">
        <img src="/logo.svg" alt="Talegaon Fresh" className="brand-logo" />
      </a>
      <div className="d-flex align-items-center gap-2 ms-auto">
        <a className="nav-link d-none d-lg-inline" href="#products">Products</a>
        <a className="nav-link d-none d-lg-inline" href="#how-it-works">How it works</a>
        <a className="nav-link d-none d-lg-inline" href="#about">About</a>
        <a className="btn btn-success rounded-pill px-3" href={whatsappUrl()} target="_blank" rel="noreferrer"><i className="bi bi-whatsapp me-2"></i>Order on WhatsApp</a>
      </div>
    </nav>
  </header>;
}

function App() {
  const [active, setActive] = useState('All');
  const filtered = useMemo(() => active === 'All' ? products : products.filter(p => p.category === active), [active]);

  return <div>
    <Header />

    <main id="home">
      <section className="hero">
        <div className="hero-pattern" aria-hidden="true"></div>
        <div className="container position-relative">
          <div className="row align-items-center g-5">
            <div className="col-lg-6">
              <span className="eyebrow"><i className="bi bi-leaf-fill me-2"></i>Fresh • Healthy • Natural</span>
              <h1>Fresh fruits & vegetables <span>in Talegaon.</span></h1>
              <p className="hero-copy">Freshly selected produce, simple WhatsApp ordering and convenient local home delivery.</p>
              <div className="d-flex flex-column flex-sm-row gap-3 mt-4">
                <a className="btn btn-success btn-lg rounded-pill px-4" href="#products">Shop Fresh Products <i className="bi bi-arrow-down ms-2"></i></a>
                <a className="btn btn-outline-success btn-lg rounded-pill px-4" href={whatsappUrl()} target="_blank" rel="noreferrer"><i className="bi bi-whatsapp me-2"></i>Order on WhatsApp</a>
              </div>
              <div className="hero-points">
                <span><i className="bi bi-check-circle-fill"></i> Local delivery</span>
                <span><i className="bi bi-check-circle-fill"></i> Price confirmed before order</span>
                <span><i className="bi bi-check-circle-fill"></i> UPI or COD</span>
              </div>
            </div>
            <div className="col-lg-6">
              <div className="produce-hero" aria-label="Fresh fruits and vegetables">
                <div className="produce-badge"><i className="bi bi-stars"></i><strong>Fresh today</strong><small>Selected for your family</small></div>
                <div className="produce-basket"><span>🥬</span><span>🥦</span><span>🍅</span><span>🥕</span><span>🫑</span><span>🍌</span><span>🍎</span><span>🍊</span></div>
                <div className="floating-card floating-one"><i className="bi bi-truck"></i><div><strong>Home delivery</strong><small>Across selected Talegaon areas</small></div></div>
                <div className="floating-card floating-two"><i className="bi bi-shield-check"></i><div><strong>Fresh selection</strong><small>Quality checked before delivery</small></div></div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="benefits">
        <div className="container"><div className="row g-0">
          {[['bi-leaf','Freshly Selected','Daily-use produce'],['bi-shield-check','Good Quality','Carefully selected'],['bi-truck','Home Delivery','Selected Talegaon areas'],['bi-wallet2','Flexible Payment','UPI or Cash on Delivery']].map(([icon,title,text]) => <div className="col-6 col-lg-3" key={title}><div className="benefit"><i className={'bi '+icon}></i><div><strong>{title}</strong><small>{text}</small></div></div></div>)}
        </div></div>
      </section>

      <section className="section" id="products">
        <div className="container">
          <div className="section-heading"><div><span className="eyebrow">Our catalogue</span><h2>Fresh products for your kitchen</h2></div><a href={whatsappUrl()} target="_blank" rel="noreferrer">Need something else? WhatsApp us <i className="bi bi-arrow-up-right"></i></a></div>
          <div className="category-row">{['All', ...categories.map(c => c.name)].map(name => <button className={'category-pill '+(active === name ? 'active' : '')} key={name} onClick={() => setActive(name)}>{name}</button>)}</div>
          <div className="row g-4 mt-1">
            {filtered.map(product => <div className="col-6 col-md-4 col-lg-3" key={product.name}>
              <article className="product-card">
                <button className="heart" aria-label={'Order '+product.name} onClick={() => window.open(whatsappUrl(product), '_blank')}><i className="bi bi-whatsapp"></i></button>
                <div className="product-visual"><span>{product.icon}</span></div>
                <div className="product-body"><small>{product.category}</small><h3>{product.name}</h3><p>{product.unit}</p><a href={whatsappUrl(product)} target="_blank" rel="noreferrer" className="btn btn-success w-100 rounded-3"><i className="bi bi-whatsapp me-2"></i>Ask today's price</a></div>
              </article>
            </div>)}
          </div>
        </div>
      </section>

      <section className="section soft-section" id="how-it-works">
        <div className="container">
          <div className="text-center section-title"><span className="eyebrow">Simple ordering</span><h2>Fresh produce without the hassle.</h2><p>We're keeping ordering simple while we build our local customer community.</p></div>
          <div className="row g-4 mt-3">{[['01','Browse','Explore our fresh product catalogue.'],['02','WhatsApp','Send us what you need and your address.'],['03','Confirm','We confirm availability and today’s price.'],['04','Deliver','Choose UPI or COD and receive your order.']].map(([n,t,d]) => <div className="col-md-6 col-lg-3" key={n}><div className="step-card"><span>{n}</span><h3>{t}</h3><p>{d}</p></div></div>)}</div>
        </div>
      </section>

      <section className="section about-section" id="about">
        <div className="container"><div className="about-panel"><div><span className="eyebrow">Why Talegaon Fresh</span><h2>Your local source for fresh everyday produce.</h2><p>We are starting local, listening to customers and focusing on fresh fruits and vegetables with convenient doorstep delivery in Talegaon.</p></div><div className="about-points"><span><i className="bi bi-check2"></i> Local-first service</span><span><i className="bi bi-check2"></i> Freshness-focused selection</span><span><i className="bi bi-check2"></i> Simple WhatsApp ordering</span><span><i className="bi bi-check2"></i> Price confirmed before purchase</span></div></div></div>
      </section>

      <section className="final-cta"><div className="container"><div className="cta-inner"><div><span className="eyebrow">Ready to order?</span><h2>Let's get fresh produce to your doorstep.</h2></div><a className="btn btn-light btn-lg rounded-pill px-4" href={whatsappUrl()} target="_blank" rel="noreferrer"><i className="bi bi-whatsapp me-2"></i>Chat on WhatsApp</a></div></div></section>
    </main>

    <footer><div className="container d-flex flex-column flex-md-row justify-content-between gap-3"><span>© {new Date().getFullYear()} Talegaon Fresh</span><span>Fresh fruits & vegetables • Talegaon</span></div></footer>
  </div>;
}

export default App;