{shell} = require 'electron'
About = require '../lib/main'
MockUpdater = require './mocks/updater'
etch = require 'etch'

describe "updates", ->
  [aboutElement, updateManager, workspaceElement] = []

  scheduler = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
      atom.packages.activatePackage('about')
    runs ->
      spyOn(atom.autoUpdater, 'getState').andReturn('idle')
      spyOn(atom.autoUpdater, 'checkForUpdate')
      spyOn(atom.autoUpdater, 'platformSupportsUpdates').andReturn(true)
      jasmine.attachToDOM(workspaceElement)
      atom.workspace.open('atom://about')
    waitsFor ->
      atom.workspace.getActivePaneItem()
    runs ->
      aboutElement = workspaceElement.querySelector('.about')
      updateManager = About.updateManager
      scheduler = About.aboutView.getScheduler()

  describe "when the updates are not supported by the platform", ->
    it "hides the auto update UI", ->
      atom.autoUpdater.platformSupportsUpdates.andReturn(false)
      updateManager.resetState()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.about-updates')).not.toBeVisible()

  describe "when updates are supported by the platform", ->
    beforeEach ->
      atom.autoUpdater.platformSupportsUpdates.andReturn(true)
      updateManager.resetState()

    it "shows the auto update UI", ->
      expect(aboutElement.querySelector('.about-updates')).toBeVisible()

    it "shows the correct panels when the app checks for updates and there is no update available", ->
      expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()

      runs ->
        MockUpdater.checkForUpdate()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-up-to-date')).not.toBeVisible()
        expect(aboutElement.querySelector('.app-checking-for-updates')).toBeVisible()

        MockUpdater.updateNotAvailable()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-up-to-date')).toBeVisible()
        expect(aboutElement.querySelector('.app-checking-for-updates')).not.toBeVisible()

    it "shows the correct panels when the app checks for updates and there is no update available", ->
      # TODO: remove when this function is in beta / stable
      # return unless atom.autoUpdater?.onUpdateError?

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()

      runs ->
        MockUpdater.checkForUpdate()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-up-to-date')).not.toBeVisible()
        expect(aboutElement.querySelector('.app-checking-for-updates')).toBeVisible()

      runs ->
        spyOn(atom.autoUpdater, 'getErrorMessage').andReturn('an error message')
        MockUpdater.updateError()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-update-error')).toBeVisible()
        expect(aboutElement.querySelector('.app-error-message').textContent).toBe 'an error message'
        expect(aboutElement.querySelector('.app-checking-for-updates')).not.toBeVisible()
        expect(aboutElement.querySelector('.about-update-action-button').disabled).toBe false
        expect(aboutElement.querySelector('.about-update-action-button').textContent).toBe 'Check now'

    it "shows the correct panels and button states when the app checks for updates and an update is downloaded", ->
      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()
        expect(aboutElement.querySelector('.about-update-action-button').disabled).toBe false
        expect(aboutElement.querySelector('.about-update-action-button').textContent).toBe 'Check now'

      runs ->
        MockUpdater.checkForUpdate()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-up-to-date')).not.toBeVisible()
        expect(aboutElement.querySelector('.app-checking-for-updates')).toBeVisible()
        expect(aboutElement.querySelector('.about-update-action-button').disabled).toBe true
        expect(aboutElement.querySelector('.about-update-action-button').textContent).toBe 'Check now'

        MockUpdater.downloadUpdate()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-checking-for-updates')).not.toBeVisible()
        expect(aboutElement.querySelector('.app-downloading-update')).toBeVisible()
        # TODO: at some point it would be nice to be able to cancel an update download, and then this would be a cancel button
        expect(aboutElement.querySelector('.about-update-action-button').disabled).toBe true
        expect(aboutElement.querySelector('.about-update-action-button').textContent).toBe 'Check now'

        MockUpdater.finishDownloadingUpdate(42)

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-downloading-update')).not.toBeVisible()
        expect(aboutElement.querySelector('.app-update-available-to-install')).toBeVisible()

        expect(aboutElement.querySelector('.app-update-available-to-install .about-updates-version').textContent).toBe('42')
        expect(aboutElement.querySelector('.about-update-action-button').disabled).toBe false
        expect(aboutElement.querySelector('.about-update-action-button').textContent).toBe 'Restart and install'

    it "opens the release notes for the downloaded release when the release notes link are clicked", ->
      MockUpdater.finishDownloadingUpdate('1.2.3')

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        spyOn(shell, 'openExternal')
        link = aboutElement.querySelector('.app-update-available-to-install .about-updates-release-notes')
        link.click()

        args = shell.openExternal.mostRecentCall.args
        expect(shell.openExternal).toHaveBeenCalled()
        expect(args[0]).toContain '/v1.2.3'

    it "executes checkForUpdate() when the check for update button is clicked", ->
      button = aboutElement.querySelector('.about-update-action-button')
      button.click()
      expect(atom.autoUpdater.checkForUpdate).toHaveBeenCalled()

    it "executes restartAndInstallUpdate() when the restart and install button is clicked", ->
      spyOn(atom.autoUpdater, 'restartAndInstallUpdate')
      MockUpdater.finishDownloadingUpdate(42)

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        button = aboutElement.querySelector('.about-update-action-button')
        button.click()
        expect(atom.autoUpdater.restartAndInstallUpdate).toHaveBeenCalled()

    it "starts in the same state as atom's AutoUpdateManager", ->
      atom.autoUpdater.getState.andReturn('downloading')
      updateManager.resetState()

      waitsForPromise ->
        scheduler.getNextUpdatePromise()

      runs ->
        expect(aboutElement.querySelector('.app-checking-for-updates')).not.toBeVisible()
        expect(aboutElement.querySelector('.app-downloading-update')).toBeVisible()
        expect(aboutElement.querySelector('.about-update-action-button').disabled).toBe true
        expect(aboutElement.querySelector('.about-update-action-button').textContent).toBe 'Check now'

    describe "when core.automaticallyUpdate is toggled", ->
      beforeEach ->
        atom.config.set('core.automaticallyUpdate', true)
        atom.autoUpdater.checkForUpdate.reset()

      it "shows the auto update UI", ->
        waitsForPromise ->
          scheduler.getNextUpdatePromise()

        runs ->
          expect(aboutElement.querySelector('.about-auto-updates input').checked).toBe true
          expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()
          expect(aboutElement.querySelector('.about-default-update-message').textContent).toBe 'Atom will check for updates automatically'

          atom.config.set('core.automaticallyUpdate', false)

        waitsForPromise ->
          scheduler.getNextUpdatePromise()

        runs ->
          expect(aboutElement.querySelector('.about-auto-updates input').checked).toBe false
          expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()
          expect(aboutElement.querySelector('.about-default-update-message').textContent).toBe 'Automatic updates are disabled please check manually'


      it "updates config and the UI when the checkbox is used to toggle", ->
        expect(aboutElement.querySelector('.about-auto-updates input').checked).toBe true

        aboutElement.querySelector('.about-auto-updates input').click()

        waitsForPromise ->
          scheduler.getNextUpdatePromise()

        runs ->
          expect(atom.config.get('core.automaticallyUpdate')).toBe false
          expect(aboutElement.querySelector('.about-auto-updates input').checked).toBe false
          expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()
          expect(aboutElement.querySelector('.about-default-update-message').textContent).toBe 'Automatic updates are disabled please check manually'

          aboutElement.querySelector('.about-auto-updates input').click()

        waitsForPromise ->
          scheduler.getNextUpdatePromise()

        runs ->
          expect(atom.config.get('core.automaticallyUpdate')).toBe true
          expect(aboutElement.querySelector('.about-auto-updates input').checked).toBe true
          expect(aboutElement.querySelector('.about-default-update-message')).toBeVisible()
          expect(aboutElement.querySelector('.about-default-update-message').textContent).toBe 'Atom will check for updates automatically'

      it "checks for update when the about page is shown", ->
        expect(atom.autoUpdater.checkForUpdate).not.toHaveBeenCalled()

        atom.workspace.getActivePane().destroyActiveItem()
        atom.workspace.open('atom://about')

        About.aboutView.componentDidMount ->
          expect(atom.autoUpdater.checkForUpdate).toHaveBeenCalled()

      it "does not check for update when the about page is shown and the update manager is not in the idle state", ->
        atom.autoUpdater.getState.andReturn('downloading')
        updateManager.resetState()
        expect(atom.autoUpdater.checkForUpdate).not.toHaveBeenCalled()

        atom.workspace.getActivePane().destroyActiveItem()
        atom.workspace.open('atom://about')

        About.aboutView.componentDidMount ->
          expect(atom.autoUpdater.checkForUpdate).not.toHaveBeenCalled()

      it "does not check for update when the about page is shown and auto updates are turned off", ->
        atom.config.set('core.automaticallyUpdate', false)
        expect(atom.autoUpdater.checkForUpdate).not.toHaveBeenCalled()

        atom.workspace.getActivePane().destroyActiveItem()
        atom.workspace.open('atom://about')

        About.aboutView.componentDidMount ->
          expect(atom.autoUpdater.checkForUpdate).not.toHaveBeenCalled()