using System;
using System.Diagnostics;
using System.ServiceModel;
using System.IO;
using System.Reflection;

namespace DistributedDeployment
{
  [ServiceContract]
  public interface IRemoteCommandService
  {
    [OperationContract]
    string Execute(string securityToken, string cmdPath, string ip, string port);
  }

  internal class RemoteCommandService : IRemoteCommandService
  {
    private readonly string _securityToken;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="securityToken"></param>
    public RemoteCommandService(string securityToken)
    {
      _securityToken = securityToken;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="token"></param>
    /// <param name="cmdPath"></param>
    /// <param name="ip"></param>
    /// <param name="port"></param>
    /// <returns></returns>
    public string Execute(string token, string cmdPath, string ip, string port)
    {
      if (_securityToken != token)
      {
        Trace.TraceError("Execute Process called");
        return "Invalid security token";
      }

      try
      {
        Trace.TraceInformation("Execute Process called");
        Trace.TraceInformation(string.Format("Passed target server settings: {0} {1}", ip, port));

        if (!File.Exists(string.Format("{0}\\{1}", Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), cmdPath)))
        {
          Trace.TraceWarning(string.Format("File {0}\\{1} does not exists", Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), cmdPath));
          Trace.TraceWarning("Exited Execute method");
          return null;
        }

        Process objProcess = new Process();
        objProcess.StartInfo.UseShellExecute = false;
        objProcess.StartInfo.RedirectStandardOutput = true;
        objProcess.StartInfo.CreateNoWindow = true;
        objProcess.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
        objProcess.StartInfo.FileName = string.Format("{0}\\{1}", Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), cmdPath);
        objProcess.StartInfo.Arguments = String.Format("{0} {1}", ip, port);

        try
        {
          Trace.TraceInformation(string.Format("Try to execute {0}\\{1}", Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), cmdPath));
          objProcess.Start();
          return null;
        }
        catch
        {
          Trace.TraceError("Executing Batchfile Failed");
          throw new Exception("Error");
        }
      }
      catch (Exception ex)
      {
        return ex.Message;
      }
    }
  }
}