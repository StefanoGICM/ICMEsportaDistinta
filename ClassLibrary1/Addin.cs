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
        }

    

        public void OnCmd(ref EdmCmd poCmd, ref EdmCmdData[] ppoData)
        {
            string @DEDID;
            string @DEDREV;

            string query;
            int version;
            int iDocument;


            // Handle the menu command
            if (poCmd.meCmdType == EdmCmdType.EdmCmd_CardButton)
            {
                if (poCmd.mlCmdID == 0 && poCmd.mbsComment=="ESPORTADISTINTAPDM")
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

   
            }


        }



    }
}
