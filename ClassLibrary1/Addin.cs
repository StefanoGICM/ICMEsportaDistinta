using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using EPDM.Interop.epdm;
using System.Windows.Forms;
using System.Data.SqlClient;
using System.Data;
using System.Diagnostics;

namespace ICM.SWPDM.EsportaDistintaAddin
{
    public class AddIn : IEdmAddIn5
    {

        IEdmVault5 vault = null;
        string sFileName = null;


        public void GetAddInInfo(ref EdmAddInInfo poInfo, IEdmVault5 poVault, IEdmCmdMgr5 poCmdMgr)
        {

            this.vault = poVault;

            //Specify information to display in the add-in's Properties dialog box
            poInfo.mbsAddInName = "ICM Add-in";
            poInfo.mbsCompany = "ICM";
            poInfo.mbsDescription = "Esporta Distinta PDM";
            poInfo.mlAddInVersion = 1;

            //Specify the minimum required version of SolidWorks PDM Professional
            poInfo.mlRequiredVersionMajor = 6;
            poInfo.mlRequiredVersionMinor = 4;

            //Notify the add-in when a file data card button is clicked
            poCmdMgr.AddHook(EdmCmdType.EdmCmd_CardButton);

            poCmdMgr.AddHook(EdmCmdType.EdmCmd_TaskSetup);
            poCmdMgr.AddHook(EdmCmdType.EdmCmd_TaskSetupButton);
            poCmdMgr.AddHook(EdmCmdType.EdmCmd_TaskRun);
            poCmdMgr.AddHook(EdmCmdType.EdmCmd_TaskDetails);

        }

        private void OnTaskDetails(ref EdmCmd poCmd, ref EdmCmdData[] ppoData)
        {
            try
            {
                IEdmTaskInstance TaskInstance = (IEdmTaskInstance)poCmd.mpoExtra;
                if ((TaskInstance != null))
                {


                    poCmd.mbsComment = "Dettagli Esporta Distinta a Gestionale";

                }

            }
            catch (System.Runtime.InteropServices.COMException ex)
            {
                MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }

        }


        private void OnTaskRun(ref EdmCmd poCmd, ref EdmCmdData[] ppoData)
        {

            int size;

            size = ppoData.Length;

            string ProgresssMsg = null;

            int iDocument;

            string sFileName;

            int version;

            this.vault = (IEdmVault5)poCmd.mpoVault;


            try
            {
                IEdmTaskInstance TaskInstance = default(IEdmTaskInstance);
                TaskInstance = (IEdmTaskInstance)poCmd.mpoExtra;
                if ((TaskInstance != null))
                {
                    TaskInstance.SetStatus(EdmTaskStatus.EdmTaskStat_Running);
                    TaskInstance.SetProgressRange(100, 0, "Task is running.");

                    ProgresssMsg = "";


                    for (int i = 0; i < size; i++)
                    {

                        int ID = ppoData[i].mlObjectID1;

                        iDocument = ID;


                        IEdmFile17 aFile = (IEdmFile17)this.vault.GetObject(EdmObjectType.EdmObject_File, ID);

                        IEdmFolder5 aFolder = default(IEdmFolder5);
                        IEdmPos5 aPos = default(IEdmPos5);

                        aPos = aFile.GetFirstFolderPosition();
                        aFolder = aFile.GetNextFolder(aPos);


                        string cLocalPath = aFile.GetLocalPath(aFolder.ID);
                        sFileName = cLocalPath;

                        bool bSuccess;

                        bSuccess = false;

                        
                        version = aFile.CurrentVersion;

                        EsportaDistinta espDist = new EsportaDistinta();
                        espDist.OpenLog(System.IO.Path.GetFileName(sFileName));

                        EdmStrLst5 cfgList = default(EdmStrLst5);
                        cfgList = aFile.GetConfigurations();

                        IEdmPos5 pos = default(IEdmPos5);
                        pos = cfgList.GetHeadPosition();
                        string cfgName = null;

                        Task asyncTask;
                        while (!pos.IsNull)
                        {
                            cfgName = cfgList.GetNext(pos);

                            /* salta configurazione @*/

                            if (cfgName == "@")
                                continue;


                            try
                            {
                                espDist.WriteLog("-----------------------------------------------------------------------");
                                espDist.WriteLog("Esportazione " + sFileName + " (configurazione " + cfgName + ")");
                                espDist.WriteLog("-----------------------------------------------------------------------");


                                
                                espDist.IniziaEsportazione(iDocument, sFileName, version, cfgName, this.vault, true, 2, "UR", "");

                                espDist.CommitLog(true);
                                espDist.WriteLog("-----------------------------------------------------------------------");
                                espDist.WriteLog("Esportazione terminata con successo");
                                espDist.WriteLog("-----------------------------------------------------------------------");

                                bSuccess = true;
                                ProgresssMsg = "Task Completed";




                            }
                            catch (Exception ex)
                            {
                                espDist.WriteLog(ex.Message);
                                espDist.CommitLog(false);
                                espDist.WriteLog("-----------------------------------------------------------------------");
                                espDist.WriteLog("Esportazione interrotta per errori");
                                espDist.WriteLog("-----------------------------------------------------------------------");

                                ProgresssMsg = "Task Failed";




                            }


                        }

                        espDist.CloseLog();
                        espDist.MoveLog(bSuccess);

                    }



                    TaskInstance.SetProgressPos(100, ProgresssMsg);
                    TaskInstance.SetStatus(EdmTaskStatus.EdmTaskStat_DoneOK, 0, "", null, ProgresssMsg);

                }

            }
            catch (System.Runtime.InteropServices.COMException ex)
            {
                MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + " " + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void OnTaskSetup(ref EdmCmd poCmd, ref EdmCmdData[] ppoData)
        {
            try
            {
                IEdmTaskProperties props = (IEdmTaskProperties)poCmd.mpoExtra;


                if ((props != null))
                {
                    //Set the task properties
                    props.TaskFlags = (int)EdmTaskFlag.EdmTask_SupportsScheduling + (int)EdmTaskFlag.EdmTask_SupportsDetails + (int)EdmTaskFlag.EdmTask_SupportsChangeState;


                    EdmTaskSetupPage[] pages = new EdmTaskSetupPage[1];
                    //Page name that appears in the
                    //navigation pane of the Add Task dialog
                    //in the Administration tool

                    props.SetSetupPages(pages);

                }

            }
            catch (System.Runtime.InteropServices.COMException ex)
            {
                MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + " " + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        //'Called when the user clicks OK or Cancel in the 
        //'task property dialog box
        private void OnTaskSetupButton(ref EdmCmd poCmd, ref EdmCmdData[] ppoData)
        {
            try
            {
                //Custom setup page, SetupPageObj, is created
                //in method Class1::OnTaskSetup; SetupPage::StoreData 
                //saves the contents of the list box to poCmd.mpoExtra 
                //in the IEdmTaskProperties interface

            }
            catch (System.Runtime.InteropServices.COMException ex)
            {
                MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + " " + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }


        public void OnCmd(ref EdmCmd poCmd, ref EdmCmdData[] ppoData)
        {
            string @DEDID;
            string @DEDREV;

            string query;
            int version;
            int iDocument;

            try
            {
                switch (poCmd.meCmdType)
                {
                    // Handle the menu command
                    case EdmCmdType.EdmCmd_CardButton:

                        if (poCmd.mlCmdID == 0 && poCmd.mbsComment == "ESPORTADISTINTAPDM")
                        {

                            if (ppoData.Length == 1)
                            {

                                int ID = ppoData[0].mlObjectID1;

                                iDocument = ID;


                                IEdmFile17 aFile = (IEdmFile17)this.vault.GetObject(EdmObjectType.EdmObject_File, ID);

                                IEdmFolder5 aFolder = default(IEdmFolder5);
                                IEdmPos5 aPos = default(IEdmPos5);

                                aPos = aFile.GetFirstFolderPosition();
                                aFolder = aFile.GetNextFolder(aPos);

                                string cLocalPath = aFile.GetLocalPath(aFolder.ID);

                                sFileName = cLocalPath;
                                version = aFile.CurrentVersion;

                                try
                                {


                                    if (sFileName != null)
                                    {


                                        EsportaDistintaForm esportaDistintaForm = new EsportaDistintaForm(iDocument, sFileName, version, this.vault);

                                        esportaDistintaForm.Show();

                                    }

                                }

                                catch (System.Runtime.InteropServices.COMException ex)
                                {
                                    System.Windows.Forms.MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + " " + ex.Message);
                                }
                                catch (Exception ex)
                                {
                                    System.Windows.Forms.MessageBox.Show(ex.Message);
                                }
                            }

                        }


                        break;

                        //Called from the Administration tool when
                        //the user selects this task add-in from the
                        //drop-down list and whenever this task is
                        //subsequently edited in the Administration tool
                        case EdmCmdType.EdmCmd_TaskSetup:
                            OnTaskSetup(ref poCmd, ref ppoData);

                            break;
                        //Sent when the user clicks OK or
                        //Cancel in the task property dialog box
                        case EdmCmdType.EdmCmd_TaskSetupButton:
                            OnTaskSetupButton(ref poCmd, ref ppoData);

                            break;
                        //Called when an instance of the
                        //task is run
                        case EdmCmdType.EdmCmd_TaskRun:
                            OnTaskRun(ref poCmd, ref ppoData);

                            break;
                        //Called from the Task List in the
                        //Administration tool when the task details
                        //dialog is displayed
                        case EdmCmdType.EdmCmd_TaskDetails:
                            OnTaskDetails(ref poCmd, ref ppoData);
                            break;

                }

   
            }
            catch (System.Runtime.InteropServices.COMException ex)
            {
                MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }


        }



    }
}
