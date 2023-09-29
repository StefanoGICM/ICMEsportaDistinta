using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using EspDist = ICM.SWPDM.EsportaDistintaAddin;
using EPDM.Interop.epdm;
using System.Timers;
using System.IO;

namespace ICMEsportaDistintaWindowsService1
{
    public partial class Service1 : ServiceBase
    {

        EspDist.EsportaDistinta espDist;
        string vaultName = "PDMTEST";
        System.Timers.Timer timer = new System.Timers.Timer();
        IEdmVault5 vault;
        StreamWriter outputFile;

        string cLogFileName;
        string cLogFileNamePath;

        bool bSemaforo;



        public Service1()
        {
            InitializeComponent();
        }

        public void icmLoginVault()
        {

            if (vaultName == "SandBox2")
            {

                ((IEdmVault13)vault).LoginEx("admin", "", vaultName);

            }
            else if (vaultName == "PDMTEST")
            {

                ((IEdmVault13)vault).LoginEx("admin", "", vaultName);

            }




        }



        protected override void OnStart(string[] args)
        {

            //Debugger.Launch();




            timer.Elapsed += new ElapsedEventHandler(OnElapsedTime);
            timer.Interval = 10000; //number in milisecinds
            timer.Enabled = true;

            vault = new EdmVault5();

            icmLoginVault();

            OpenLog(vault.RootFolderPath);

            WriteLog("On Start iniziato");


            WriteLog(vault.RootFolderPath);

            espDist = new EspDist.EsportaDistinta(vault, 10);


            WriteLog("On Start terminato");

            bSemaforo = false;


        }



        protected override void OnStop()
        {
            WriteLog("On Stop iniziato");
            WriteLog("On Stop terminato");
            CloseLog();


        }

        public void OpenLog(string vaultRootFolderPath)
        {


            cLogFileName = "workerlog_" + DateTime.Now.ToString("yyyy'_'MM'_'dd'T'HH'_'mm'_'ss") + ".txt";


            if (!Directory.Exists(vaultRootFolderPath + @"\Log"))
            {

                Directory.CreateDirectory(vaultRootFolderPath + @"\Log");

            }

            if (!Directory.Exists(vaultRootFolderPath + @"\Log\EsportaGestionale"))
            {

                Directory.CreateDirectory(vaultRootFolderPath + @"\Log\EsportaGestionale");

            }

            cLogFileNamePath = vaultRootFolderPath + @"\Log\EsportaGestionale";

            //MessageBox.Show(Path.Combine(cLogFileNamePath, cLogFileName));

            outputFile = new StreamWriter(Path.Combine(cLogFileNamePath, cLogFileName));

        }


        public void WriteLog(string content)
        {

            if (outputFile != null)
                outputFile.WriteLine(DateTime.Now.ToString("yyyy'_'MM'_'dd'T'HH'_'mm'_'ss") + ": " + content);

        }


        public void CloseLog()
        {
            if (outputFile != null)
                outputFile.Close();

        }


        private void OnElapsedTime(object source, ElapsedEventArgs e)
        {
            try
            {
                if (!bSemaforo)
                {

                    if (espDist != null)
                    {

                        //Debugger.Launch();

                        bSemaforo = true;
                        espDist.ProcessaElementi(this.vault, 5);
                        bSemaforo = false;

                    }

                }
                else
                {

                    WriteLog("Attenzione Worker non terminato prima di essere rilanciato;  ");

                }

            }

            catch (Exception ex)
            {
                WriteLog("Errore: " + ex.Message);

                bSemaforo = false;

                // Terminates this process and returns an exit code to the operating system.
                // This is required to avoid the 'BackgroundServiceExceptionBehavior', which
                // performs one of two scenarios:
                // 1. When set to "Ignore": will do nothing at all, errors cause zombie services.
                // 2. When set to "StopHost": will cleanly stop the host, and log errors.
                //
                // In order for the Windows Service Management system to leverage configured
                // recovery options, we need to terminate the process with a non-zero exit code.
                //Environment.Exit(1);
            }

        }
    }





}
