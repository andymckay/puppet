#! /usr/bin/env ruby

require 'spec_helper'

describe "Puppet::Util::Windows::User", :if => Puppet.features.microsoft_windows? do
  describe "2003 without UAC" do
    before :each do
      Facter.stubs(:value).with(:kernelmajversion).returns("5.2")
    end

    it "should be an admin if user's token contains the Administrators SID" do
      Puppet::Util::Windows::User.expects(:check_token_membership).returns(true)
      Puppet::Util::Windows::Process.expects(:elevated_security?).never

      Puppet::Util::Windows::User.should be_admin
    end

    it "should not be an admin if user's token doesn't contain the Administrators SID" do
      Puppet::Util::Windows::User.expects(:check_token_membership).returns(false)
      Puppet::Util::Windows::Process.expects(:elevated_security?).never

      Puppet::Util::Windows::User.should_not be_admin
    end

    it "should raise an exception if we can't check token membership" do
      Puppet::Util::Windows::User.expects(:check_token_membership).raises(Puppet::Util::Windows::Error, "Access denied.")
      Puppet::Util::Windows::Process.expects(:elevated_security?).never

      lambda { Puppet::Util::Windows::User.admin? }.should raise_error(Puppet::Util::Windows::Error, /Access denied./)
    end
  end

  describe "2008 with UAC" do
    before :each do
      Facter.stubs(:value).with(:kernelmajversion).returns("6.0")
    end

    it "should be an admin if user is running with elevated privileges" do
      Puppet::Util::Windows::Process.stubs(:elevated_security?).returns(true)
      Puppet::Util::Windows::User.expects(:check_token_membership).never

      Puppet::Util::Windows::User.should be_admin
    end

    it "should not be an admin if user is not running with elevated privileges" do
      Puppet::Util::Windows::Process.stubs(:elevated_security?).returns(false)
      Puppet::Util::Windows::User.expects(:check_token_membership).never

      Puppet::Util::Windows::User.should_not be_admin
    end

    it "should raise an exception if the process fails to open the process token" do
      Puppet::Util::Windows::Process.stubs(:elevated_security?).raises(Puppet::Util::Windows::Error, "Access denied.")
      Puppet::Util::Windows::User.expects(:check_token_membership).never

      lambda { Puppet::Util::Windows::User.admin? }.should raise_error(Puppet::Util::Windows::Error, /Access denied./)
    end
  end

  describe "module function" do
    let(:username) { 'fabio' }
    let(:bad_password) { 'goldilocks' }
    let(:logon_fail_msg) { /Failed to logon user "fabio":  Logon failure: unknown user name or bad password./ }

    describe "load_profile" do
      it "should raise an error when provided with an incorrect username and password" do
        lambda { Puppet::Util::Windows::User.load_profile(username, bad_password) }.should raise_error(Puppet::Util::Windows::Error, logon_fail_msg)
      end

      it "should raise an error when provided with an incorrect username and nil password" do
        lambda { Puppet::Util::Windows::User.load_profile(username, nil) }.should raise_error(Puppet::Util::Windows::Error, logon_fail_msg)
      end
    end

    describe "logon_user" do
      it "should raise an error when provided with an incorrect username and password" do
        lambda { Puppet::Util::Windows::User.logon_user(username, bad_password) }.should raise_error(Puppet::Util::Windows::Error, logon_fail_msg)
      end

      it "should raise an error when provided with an incorrect username and nil password" do
        lambda { Puppet::Util::Windows::User.logon_user(username, nil) }.should raise_error(Puppet::Util::Windows::Error, logon_fail_msg)
      end
    end

    describe "password_is?" do
      it "should return false given an incorrect username and password" do
        Puppet::Util::Windows::User.password_is?(username, bad_password).should be_false
      end

      it "should return false given an incorrect username and nil password" do
        Puppet::Util::Windows::User.password_is?(username, nil).should be_false
      end

      it "should return false given a nil username and an incorrect password" do
        Puppet::Util::Windows::User.password_is?(nil, bad_password).should be_false
      end
    end

    describe "check_token_membership" do
      it "should not raise an error" do
        # added just to call an FFI code path on all platforms
        lambda { Puppet::Util::Windows::User.check_token_membership }.should_not raise_error
      end
    end
  end
end
