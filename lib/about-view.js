/** @babel */
/** @jsx etch.dom */

import {Disposable} from 'atom'
import etch from 'etch'
import shell from 'shell'
import AtomLogo from './atom-logo'
import UpdateView from './update-view'

class AboutView {
  constructor ({uri, updateManager}) {
    this.state = {
      uri,
      updateManager,
      version: atom.getVersion()
    }
    this.handleVersionClick = this.handleVersionClick.bind(this)
    etch.initialize(this)
    etch.setScheduler(atom.views)
  }

  handleVersionClick (e) {
    e.preventDefault()
    atom.clipboard.write(this.state.version)
  }

  handleReleaseNotesClick(e) {
    e.preventDefault()
    shell.openExternal(this.state.updateManager.getReleaseNotesURLForAvailableVersion())
  }

  handleLicenseClick(e) {
    e.preventDefault()
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'application:open-license')
  }

  handleTermsOfUseClick(e) {
    e.preventDefault()
    shell.openExternal('https://help.github.com/articles/github-terms-of-service')
  }

  handleMetricsClick(e) {
    e.preventDefault()
    atom.workspace.open('atom://config/packages/metrics')
  }

  render () {
    return (
      <div className='pane-item native-key-bindings about'>
        <div className='about-container'>
          <header className='about-header'>
            <a className='about-atom-io' href='https://atom.io/'>
              <AtomLogo />
            </a>
            <div className='about-header-info'>
              <span className='about-version-container inline-block' onclick={this.handleVersionClick}>
                <span className='about-version'>{this.state.version}</span>
                <span className='icon icon-clippy about-copy-version'></span>
              </span>
              <a className='about-header-release-notes' onclick={this.handleReleaseNotesClick.bind(this)}>Release Notes</a>
            </div>
          </header>

          <UpdateView updateManager={this.state.updateManager} />

          <p className='about-metrics group-start'>
            <strong>Note:</strong> To help us improve Atom, we anonymously
            track usage metrics, such as launch time, screen size, and current
            version. See the <a className="metrics-open" dataEvent="atom-metrics" onclick={this.handleMetricsClick.bind(this)}>atom/metrics</a> package for details and instructions to disable it.
          </p>

          <div className='about-actions group-item'>
            <div className='btn-group'>
              <button className='btn view-license' onclick={this.handleLicenseClick.bind(this)}>License</button>
              <button className='btn terms-of-use' onclick={this.handleTermsOfUseClick.bind(this)}>Terms of Use</button>
            </div>
          </div>

          <div className='about-love group-start'>
            <span className='icon icon-code'/>
            <span className='inline'> with </span>
            <span className='icon icon-heart'/>
            <span className='inline'> by </span>
            <a className='icon icon-logo-github' href='https://github.com'></a>
          </div>

          <div className='about-credits group-item'>
            <span className='inline'>And the awesome </span>
            <a href='https://github.com/atom/atom/contributors'>Atom Community</a>
          </div>
        </div>
      </div>
    )
  }

  update (props, children) {
    return etch.update(this)
  }

  destroy () {
    etch.destroy(this)
  }

  serialize () {
    return {
      deserializer: this.constructor.name,
      uri: this.getURI()
    }
  }

  onDidChangeTitle () {
    return new Disposable()
  }

  onDidChangeModified () {
    return new Disposable()
  }

  getURI () {
    return this.uri
  }

  getTitle () {
    return 'About'
  }

  getIconName () {
    return 'info'
  }
}

export default AboutView