using System;
using System.ComponentModel;
using System.Configuration;
using System.Configuration.Install;
using System.Reflection;
using System.ServiceProcess;

namespace DistributedDeployment
{
  [RunInstaller(true)]
  public partial class ServiceInstaller : System.Configuration.Install.Installer
  {
    public ServiceInstaller()
    {
      InitializeComponent();

      this.Installers.Add(GetServiceInstaller());
      this.Installers.Add(GetServiceProcessInstaller());
    }

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    private System.ServiceProcess.ServiceInstaller GetServiceInstaller()
    {
      System.ServiceProcess.ServiceInstaller installer = new System.ServiceProcess.ServiceInstaller();
      installer.ServiceName = GetConfigurationValue("ServiceName");
      installer.Description = GetConfigurationValue("ServiceDescription");

      return installer;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    private ServiceProcessInstaller GetServiceProcessInstaller()
    {
      ServiceProcessInstaller installer = new ServiceProcessInstaller();
      installer.Account = ServiceAccount.LocalSystem;
      return installer;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="key"></param>
    /// <returns></returns>
    public string GetConfigurationValue(string key)
    {
      Assembly service = Assembly.GetAssembly(typeof(ServiceInstaller));
      Configuration config = ConfigurationManager.OpenExeConfiguration(service.Location);


      if (config.AppSettings.Settings[key] != null)
      {
        return config.AppSettings.Settings[key].Value;
      }
      else
      {
        throw new IndexOutOfRangeException("Settings collection does not contain the requested key:" + key);
      }
    }
  }
}
