using EPDM.Interop.epdm;
using EPDM.Interop.EPDMResultCode;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using static ICM.SWPDM.EsportaDistintaAddin.EsportaDistintaForm;
using System.Windows.Documents;
using SwDM = SolidWorks.Interop.swdocumentmgr;
using SolidWorks.Interop.swdocumentmgr;
using System.Security.Cryptography;
using System.IO;
using System.Data.Odbc;
using System.Diagnostics.Eventing.Reader;
using System.Windows.Markup;

namespace ICM.SWPDM.EsportaDistintaAddin
{
    public partial class EsportaDistinta
    {


        public int iType = 0;   /* 1 da pulsante con log in console
                                   2 da task workflow con log in file */

        public string ExpParam1;
        public string ExpParam2;

        public string ExpP1;
        public string ExpP2;
        public TraceSource TS = new TraceSource("ICMTrace");
        IEdmVault5 vault;

        IEdmFile7 aFile;
        IEdmBom bom;
        IEdmBomMgr bomMgr;
        IEdmBomView bomView;
        string connectionString;

        string cLogFileName;

        string @LogId;
        int intIdLogValue;

        string cLogFileNamePath;

        string connectionStringSWICMDATA = "Data Source='ws91';Initial Catalog = ICMSWData; User ID = sa; Password = 'P@ssw0rd'";
        string connectionStringARCA = "Data Source='gestionale';Initial Catalog = ADB_FREDDO_TEST; User ID = sa; Password = 'Logitech0'";


        string connectionStringVault;
        Dictionary<Tuple<string, string>, Tuple<string, string, int>> cacheDictionary;
        SqlConnection cnn;
        SqlConnection cnnARCA;
        //SqlConnection cnnVault;
        string sFileName;
        string cTempCodice = "NONCODIFICATO";
        int iTempContRev = 0;
        string descTecnicaITA;
        string descTecnicaENG;

        StreamWriter outputFile = default(StreamWriter);

        string sFAMIGLIA1_PREFIX;
        string sFAMIGLIA2_PREFIX;
        string sFAMIGLIA3_PREFIX;

        bool lStop;

        string cNonCodificati;

        int itmp_Consumo = 0;

        int iVersione;

        List<string> cacheFile;

        Guid currentSessionGuid;


        /*struct ReturnData
        {

            public string DEDID;
            public string DEDREV;
            public string FAMIGLIA1_PREFIX;
            public string FAMIGLIA2_PREFIX;
            public string FAMIGLIA3_PREFIX;
            public string LG;
            public string SUP_GOMMATA;
            public string PESO;
            public string DEDLinear;
            public string DEDMass;

        
        }*/


        SqlTransaction transaction;
        List<String> lFields = new List<String> {"DEDID" ,
                                                "DEDREV" ,
                                                "CATEGORIA1" ,
                                                "CATEGORIA2" ,
                                                "CATEGORIA3" ,
                                                "CATEGORIA1_PREFIX" ,
                                                "CATEGORIA2_PREFIX" ,
                                                "CATEGORIA3_PREFIX" ,
                                                "FAMIGLIA1" ,
                                                "FAMIGLIA2" ,
                                                "FAMIGLIA3" ,
                                                "FAMIGLIA1_PREFIX" ,
                                                "FAMIGLIA2_PREFIX" ,
                                                "FAMIGLIA3_PREFIX" ,
                                                "COMMESSA" ,
                                                "DEDDATE" ,
                                                "DBPATH" ,
                                                "DED_COD" ,
                                                "DED_DIS" ,
                                                "DED_FILE" ,
                                                "DEDREVDATE" ,
                                                "DEDREVDESC" ,
                                                "DEDREVUSER" ,
                                                "DEDSTATEID" ,
                                                "DEDDESC" ,
                                                "LG" ,
                                                "MATERIALE" ,
                                                "NOTA_DI_TAGLIO" ,
                                                "PESO" ,
                                                "SUP_GOMMATA" ,
                                                "TIPOLOGIA" ,
                                                "TRATT_TERM" ,
                                                "DEDSTATEID1" ,
                                                "ITEM" ,
                                                "POTENZA" ,
                                                "N_MOTORI" ,
                                                "SOTTOCOMMESSA" ,
                                                "Standard_DIN" ,
                                                "Standard_ISO" ,
                                                "Standard_UNI" ,
                                                "MPTH" ,
                                                "Produttore" ,
                                                "shmetal_AreaContorno_mm2" ,
                                                "shmetal_L1_Contorno" ,
                                                "shmetal_L2_Contorno" ,
                                                "shmetal_Piegature" ,
                                                "shmetal_RaggioDiPiegatura" ,
                                                "shmetal_Sp_Lamiera" ,
                                                "Designazione" ,
                                                "DesignazioneGeometrica" ,
                                                "DesignazioneGeometricaEN" ,
                                                "DesignazioneGeometricaENG" ,
                                                "DesignazioneGeometricaITA" ,
                                                "IngombroX" ,
                                                "IngombroY" ,
                                                "IngombroZ" ,
                                                "LargMacchina" ,
                                                "LungMacchina" ,
                                                "CATEGORIA4" ,
                                                "CATEGORIA4_PREFIX" ,
                                                "CodiceProduttore" ,
                                                "CATEGORIA0" ,
                                                "CATEGORIA0_PREFIX" ,
                                                "FaiAcquista",
                                                "Qty",
                                                "TRATT_TERMICO",
                                                "DescTecnicaITA",
                                                "DescTecnicaENG",
                                                "DescCommercialeITA",
                                                "DescCommercialeENG",
                                                "TrattFinitura",
                                                "TrattGalvanico",
                                                "TrattProtezione",
                                                "TrattSuperficiale",
                                                "Configurazione",
                                                "DEDLinear",
                                                "DEDMass",
                                                "Configuration",
                                                "ICMRefBOMGUID",
                                                "Versione",
                                                "ID"
                                                };

        public EsportaDistinta()
        {
        }



        public void OpenLog(string sFileName)
        {

            if (iType == 2)
            {
                cLogFileName = "log_" + sFileName + "_" + DateTime.Now.ToString("yyyy'_'MM'_'dd'T'HH'_'mm'_'ss") + ".txt";

                cLogFileNamePath = @"D:\LocalView\SandBox\Log\EsportaGestionale";

                outputFile = new StreamWriter(Path.Combine(cLogFileNamePath, cLogFileName));
            }

        }


        public void WriteLog(string content, TraceEventType eventType)
        {
            if (iType == 2)
              outputFile.WriteLine(content);

            if (iType == 1)
            {

                TS.WriteLine(content, eventType);
            
            }
        }

        public void WriteLog(string content)
        {
            if (iType == 2)
                outputFile.WriteLine(content);

            if (iType == 1)
            {

                TS.WriteLine(content);

            }
        }


        public void CloseLog()
        {
            if (iType == 2)
                outputFile.Close();

        }

        public void MoveLog(bool bSuccess)
        {

            if (iType == 2)
            {
                string newPath;
                string cOld;
                string cNew;


                if (bSuccess)
                    newPath = cLogFileNamePath + @"\Completed";
                else
                    newPath = cLogFileNamePath + @"\Failed";

                cOld = Path.Combine(cLogFileNamePath, cLogFileName);
                cNew = Path.Combine(newPath, cLogFileName);

                File.Move(cOld, cNew);

            }


        }


        public void IniziaEsportazione(int iDocument, string sFileName, int iVersione, string sConfigurazioni, IEdmVault5 vault, bool bOnlyTop, int iType, string sEsplodiPar1, string sEsplodiPar2)
        {

            this.ExpParam1 = sEsplodiPar1;
            this.ExpParam2 = sEsplodiPar2;

            this.ExpP1 = ExpParam1.Split((char)1)[0];
            this.ExpP2 = ExpParam1.Split((char)1)[1];

            this.iType = iType;
            
            this.vault = vault;
            this.sFileName = sFileName;
            this.iVersione = iVersione;



            string @DEDID;
            string @DEDREV;

            string query;
            string XErrore;
            object XErroreObj;

            string XWarning;

            bool lWarn;

            currentSessionGuid = Guid.NewGuid();

            WriteLog("SessionID: " + currentSessionGuid.ToString());

            DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Started;

            try
            {

                if (sFileName != null)
                {
                    WriteLog("Inizio elaborazione");

                    foreach (string sConf in sConfigurazioni.Split(','))
                    {
                        //inizializzo dizionario per la cache
                        cacheDictionary = new Dictionary<Tuple<string, string>, Tuple<string, string, int>>();

                        //Connessione al DB e inizio transazione

                        connectionString = connectionStringSWICMDATA;

                        cnn = new SqlConnection(connectionString);

                        cnn.Open();

                        //Debugger.Launch();

                        //connectionStringVault = "Data Source='database';Initial Catalog = EPDMSuite; User ID = sa; Password = 'P@ssw0rd'";
                        //cnnVault = new SqlConnection(connectionStringVault);
                        //cnnVault.Open();

                        //comincia transazione

                        WriteLog("Esportazione Distinta per Configurazione " + sConf);

                        transaction = cnn.BeginTransaction();

                        WriteLog("Cancellazione tabelle temporanee");

                        query = "DELETE FROM [dbo].[SWBOM] WHERE SessionID = '" + currentSessionGuid + "'";

                        SqlCommand command = new SqlCommand(query, cnn);
                        command.CommandTimeout = 0;
                        command.Transaction = transaction;

                        command.ExecuteNonQuery();


                        query = "DELETE FROM [dbo].[SWANAG] WHERE SessionID = '" + currentSessionGuid + "'";

                        SqlCommand command1 = new SqlCommand(query, cnn);

                        command1.Transaction = transaction;

                        command1.ExecuteNonQuery();


                        WriteLog("Importazione distinta in tabelle temporanee");

                        int iRetPromosso;

                        lStop = false;

                        cNonCodificati = "";

                        bool bNonCodificato;

                        insertSW_ANAG_BOM(iDocument, sFileName, iVersione, sConf, out @DEDID, out @DEDREV, true, false, null, null, 1, out iRetPromosso, out bNonCodificato, bOnlyTop);
                   
                        // Calcolo consumo
                        
                        WriteLog("Calcolo consumo");

                        SqlCommand command2 = new SqlCommand("dbo.ICMCalcoloConsumoSp", cnn);
                        command2.Transaction = transaction;
                        command2.CommandType = CommandType.StoredProcedure;

                        SqlParameter sqlParam = new SqlParameter("@SessionID", SqlDbType.UniqueIdentifier);
                        sqlParam.Direction = ParameterDirection.Input;
                        sqlParam.Value = currentSessionGuid;
                        command2.Parameters.Add(sqlParam);

                        sqlParam = new SqlParameter("@XErrore", SqlDbType.VarChar, 1000);
                        //sqlParam.ParameterName = "@Result";
                        //sqlParam.DbType = DbType.Boolean;
                        sqlParam.Direction = ParameterDirection.Output;
                        command2.Parameters.Add(sqlParam);

                        //MessageBox.Show("prima");

                        

                        command2.ExecuteNonQuery();

                        //MessageBox.Show("dopo");

                        XErrore = command2.Parameters["@XErrore"].Value.ToString();

                        if (!(XErrore.Trim() == "" || XErrore == null))
                        {

                            throw new ApplicationException("Errore in calcolo consumo per distinta: " + XErrore);

                        }
                        
                        
                        transaction.Commit();

                        //cnn.Close();
                        //cnnVault.Close();

                        

                        transaction = null;

                                               

                        //Importa in ARCA
                        //MessageBox.Show("Importa in ARCA");

                        WriteLog("Importazione distinta in ARCA");
                        
                        connectionString = connectionStringARCA;

                        cnnARCA = new SqlConnection(connectionString);

                        cnnARCA.Open();

                        SqlCommand cmd2 = new SqlCommand("xICM_Importa_Distinta_In_ArcaSp", cnnARCA);

                        cmd2.CommandType = CommandType.StoredProcedure;

                        cmd2.CommandTimeout = 0;

                        SqlParameter sqlParam20 = new SqlParameter("@SessionID", SqlDbType.UniqueIdentifier);
                        sqlParam20.Direction = ParameterDirection.Input;
                        sqlParam20.Value = currentSessionGuid;
                        cmd2.Parameters.Add(sqlParam20);

                        SqlParameter sqlParam21 = new SqlParameter("@POnlyTop", SqlDbType.Int);
                        sqlParam21.Direction = ParameterDirection.Input;
                        sqlParam21.Value = 0;
                        cmd2.Parameters.Add(sqlParam21);

                        
                        SqlParameter sqlParam2 = new SqlParameter("@XWarning", SqlDbType.VarChar, -1);
                        //sqlParam.ParameterName = "@Result";
                        //sqlParam.DbType = DbType.Boolean;
                        sqlParam2.Direction = ParameterDirection.Output;



                        //sqlParam2.Size = -1;

                        cmd2.Parameters.Add(sqlParam2);

                        


                        //sqlParam2.Size = -1;

                        lWarn = false;

                        cmd2.ExecuteNonQuery();

                        XWarning = cmd2.Parameters["@XWarning"].Value.ToString();

                        cnnARCA.Close();

                        transaction = cnn.BeginTransaction();

                        WriteLog("Cancellazione tabelle temporanee");

                        query = "DELETE FROM [dbo].[SWBOM] WHERE SessionID = '" + currentSessionGuid + "'";

                        command = new SqlCommand(query, cnn);
                        command.CommandTimeout = 0;
                        command.Transaction = transaction;

                        command.ExecuteNonQuery();


                        query = "DELETE FROM [dbo].[SWANAG] WHERE SessionID = '" + currentSessionGuid + "'";

                        command1 = new SqlCommand(query, cnn);

                        command1.Transaction = transaction;

                        command1.ExecuteNonQuery();

                        transaction.Commit();

                        cnn.Close();

                        if (!(XWarning.Trim() == "" || XWarning == null))
                        {                            

                            string[] warnArray = XWarning.Split((char)1);

                            foreach (string warnMessage in warnArray)
                            {

                                lWarn = true;
                                WriteLog(warnMessage, TraceEventType.Warning);

                            }


                        }

                        if (cNonCodificati != "")
                        {

                            WriteLog("Attenzione: i seguenti articoli non sono stati codificati e quindi non sono stati importati: ", TraceEventType.Warning);
                            WriteLog(cNonCodificati, TraceEventType.Warning);

                        }


                        if (lWarn || (cNonCodificati != ""))
                        {

                            MessageBox.Show("Attenzione: uno o più avvertimenti");
                        
                        }


                        cnn.Close();

                        DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;



                    }


                }
            }
            catch (System.Runtime.InteropServices.COMException ex)
            {
                DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;
                try
                {
                    if (transaction != null)
                        transaction.Rollback();



                }
                catch (Exception ex2)
                {

                    MessageBox.Show("Errore in Rollback transazione");

                }
                finally
                {
                    //MessageBox.Show("HRESULT = 0x" + ex.ErrorCode.ToString("X") + " " + ex.Message);
                    throw ex;

                }
            }
            catch (Exception ex)
            {
                DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;
                try
                {
                    if (transaction != null)
                        transaction.Rollback();

                }
                catch (Exception ex2)
                {

                    MessageBox.Show("Errore in Rollback transazione");

                }
                finally
                {
                    //MessageBox.Show(ex.Message);
                    throw ex;

                }
            }




        }


        public void insertSW_ANAG_BOM(int iDocument, string cFileName, int iVersione, string sConf, out string sDEDID, out string sDEDREV, bool first, bool bDaPromosso, string sDEDIDPromosso, string sDEDREVPromosso, double dQtyPromosso, out int iRetPromossoPar, out bool bNonCodificatoPar, bool bOnlyTop)
        {

            //Debugger.Launch();
            

            sDEDID = null;
            sDEDREV = null;

            string sDEDLinear = "";
            string sDEDMass = "";

            bNonCodificatoPar = false;

            //MessageBox.Show(cFileName + " - " + iDocument.ToString());

            if (cacheDictionary != null)
            {

                Tuple<string, string> toFind = new Tuple<string, string>(cFileName, sConf);

                if (cacheDictionary.ContainsKey(toFind))
                {
                    

                    Tuple<string, string, int> toReturn;

                    toReturn = cacheDictionary[toFind];

                    sDEDID = toReturn.Item1;
                    sDEDREV = toReturn.Item2;

                    iRetPromossoPar = toReturn.Item3;

                    return;

                }


            }

            string tmp_DEDIDP;
            string tmp_DEDREVP;
            string tmp_DEDIDC;
            string tmp_DEDREVC;
            string tmp_QTA;
            string tmp_FAMIGLIA1_PREFIX;
            string tmp_FAMIGLIA2_PREFIX;
            string tmp_FAMIGLIA3_PREFIX;
            string tmp_LG;
            string tmp_SUP_GOMMATA;
            string tmp_PESO;
            string tmp_DEDLinear = "";
            string tmp_DEDMass = "";

            IEdmFile7 aFile;
            IEdmFolder5 ppoRetParentFolder;

            string sDEDIDP = "";
            string sDEDREVP = "";

            string sDEDIDC = "";
            string sDEDREVC = "";

            string sQty = "";

            string cTipoDistinta;


            //string sConfigurazioneCostruttivaGUID;

            string sDEDIDCCut = "";
            string sDEDREVCCut = "";

            string sQtyCut = "";

            string sFamiglia1_Prefix = "";
            string sFamiglia2_Prefix = "";
            string sFamiglia3_Prefix = "";

            string XPromosso;
            int iPromosso;

            bool bThis;

            int newIdToTake = 0;
            int newVersionToTake = 0;

            Boolean bConvPromosso;

            cTipoDistinta = "";
            iPromosso = 0;

            string sFaiAcquistaLivello0 = "";

            bool bAlreadyProcessed;

            bool lAssiemePromosso = false;

            int iRetPromosso;

            // verifico se è un assieme promosso
            if (cFileName.ToUpper().EndsWith(".SLDASM"))
            {
                SqlCommand command2 = new SqlCommand("dbo.ICM_Conf_GetPromossoSP", cnn);

                command2.CommandType = CommandType.StoredProcedure;
                command2.Transaction = transaction;

                //MessageBox.Show(iDocument.ToString() + " - " + sConf + " - " + iVersione.ToString());


                SqlParameter sqlParam = command2.Parameters.Add("@DocumentID", SqlDbType.Int);
                sqlParam.Direction = ParameterDirection.Input;
                sqlParam.Value = iDocument;


                sqlParam = command2.Parameters.Add("@Conf", SqlDbType.VarChar, 50);
                sqlParam.Direction = ParameterDirection.Input;
                sqlParam.Value = sConf;

                sqlParam = command2.Parameters.Add("@RevisionNo", SqlDbType.Int);
                sqlParam.Direction = ParameterDirection.Input;
                sqlParam.Value = iVersione;

                //TS.WriteLine("Check Assieme promosso: " + iDocument.ToString() + " ----- " + sConf + " ------ " + iVersione.ToString());

                sqlParam = new SqlParameter("@Promosso", SqlDbType.Int);
                //sqlParam.ParameterName = "@Result";
                //sqlParam.DbType = DbType.Boolean;
                sqlParam.Direction = ParameterDirection.Output;
                command2.Parameters.Add(sqlParam);


                command2.ExecuteNonQuery();

                XPromosso = command2.Parameters["@Promosso"].Value.ToString();

                if (XPromosso.Trim() == "" || XPromosso == null)
                {

                    throw new ApplicationException("Errore nel verificare assieme/parte promosso: flag prmosso nullo per " + cFileName);
                }



                bConvPromosso = Int32.TryParse(XPromosso, out iPromosso);

                if (!bConvPromosso)
                {

                    throw new ApplicationException("Flag promosso non accessibile in: " + cFileName);

                }
            }
            else if (cFileName.ToUpper().EndsWith(".SLDPRT"))
            {
                iPromosso = 0;

            }
            else 
            {

                throw new ApplicationException("Distinta BOM non associata per file: " + cFileName);
            }

            iRetPromossoPar = iPromosso;

            if (first && (iPromosso == 2))
            {

                throw new ApplicationException("Errore: l'assieme/parte " + cFileName + " da esportare è promosso.");

            }


            if (cFileName.ToUpper().EndsWith(".SLDASM"))
            {
                cTipoDistinta = "DistintaAssiemePerArca";


            }
            else if (cFileName.ToUpper().EndsWith(".SLDPRT"))
            {                               
                
                cTipoDistinta = "DistintaPartePerArca";

                if (first)
                    throw new ApplicationException("Errore: l'assieme " + cFileName + " da esportare è una parte.");

                if (iPromosso == 2)
                    throw new ApplicationException("Errore: la parte " + cFileName + " da esportare è promossa.");
            }
            else
            {

                throw new ApplicationException("Distinta BOM non associata per file: " + cFileName);


            }


            aFile = (IEdmFile7)this.vault.GetFileFromPath(cFileName, out ppoRetParentFolder);

            if (aFile != null)
            {

                //MessageBox.Show(cFileName + " --- " + sConf);


                IEdmEnumeratorVariable7 enumVar;

                object[] ppoRetVars = null;
                string[] ppoRetConfs = null;
                EdmGetVarData poRetDat = new EdmGetVarData();
                string sVersion;
                string BomName;

                enumVar = (IEdmEnumeratorVariable7)aFile.GetEnumeratorVariable();
                enumVar.GetVersionVars(0, ppoRetParentFolder.ID, out ppoRetVars, out ppoRetConfs, ref poRetDat);

                sVersion = poRetDat.mlLatestVersion.ToString();

                EdmBomInfo[] derivedBOMs = null;
                aFile.GetDerivedBOMs(out derivedBOMs);

                int arrSizeBom = 0;
                
                int iBom = 0;
                arrSizeBom = derivedBOMs.Length;
                
                bool lFoundBom;
                string sNamedBom;

                string cNamedBom;
                cNamedBom = "";
                int kIndexBom;
                kIndexBom = 0;

                lFoundBom = false;
                IEdmBom namedBom;


                /* get Configuration GUID */

                bool lOK;
                object poRetValue;
                string sICMBOMGUID;
                int iIdBom;

                IEdmEnumeratorVariable8 EnumVarObj = default(IEdmEnumeratorVariable8);
                //Keeps the file open
                EnumVarObj = (IEdmEnumeratorVariable8)aFile.GetEnumeratorVariable();

                lOK = EnumVarObj.GetVar(
                    "ICMBOMGUID",
                    sConf,
                    out poRetValue);

                if (lOK)
                {

                    sICMBOMGUID = (string)poRetValue;


                    while (iBom < arrSizeBom)
                    {

                        // Cerco Named BOM
                        string sBomName;

                        sBomName = (sICMBOMGUID + "_" + sConf + "_" + sVersion);

                        sBomName = sBomName.Replace("\\", "_");

                        //MessageBox.Show(derivedBOMs[iBom].mbsBomName + (char)10 + sBomName);

                        if (derivedBOMs[iBom].mbsBomName == sBomName)
                        {
                            lFoundBom = true;                            
                            kIndexBom = iBom;
                            break;


                        }


                        iBom++;

                    }
                }
                
                
                /*if (lFoundBom)
                {



                    iIdBom = derivedBOMs[kIndexBom].mlBomID;
                    namedBom = (IEdmBom)this.vault.GetObject(EdmObjectType.EdmObject_BOM, iIdBom);

                    TS.WriteLine("Uso DerivedBOM BOM " + namedBom.Name);

                    bomView = namedBom.GetView(0);
                }
                else
                {*/

                WriteLog("Uso Computed BOM ");

                int iVersionBOM;

                iVersionBOM = -2;

                if (first)
                {
                    switch (this.ExpP1)
                    {

                        case "UV":
                            iVersionBOM = -1;
                            break;
                        case "UR":
                            /* recupera versione associata a ultima revisione */
                            iVersionBOM = GetVersionLatestRevision(aFile);
                            break;
                        case "SV":
                            /* recupera versione selezionata */
                            bool bSuccess;
                            bSuccess = int.TryParse(this.ExpParam2, out iVersionBOM);

                            if (!bSuccess)
                            {
                                throw new ApplicationException("Errore recupero versione Root iniziale");
                            }

                            break;
                    }


                }
                else
                {
                    switch (this.ExpP2)
                    {

                        case "UV":
                            iVersionBOM = -1;
                            break;
                        case "UR":
                            /* recupera versione associata a ultima revisione */
                            iVersionBOM = GetVersionLatestRevision(aFile);
                            break;
                        case "CC":
                            
                            iVersionBOM = iVersione;

                            break;
                    }

                }

                bomView = aFile.GetComputedBOM(cTipoDistinta, iVersionBOM, sConf, (int)EdmBomFlag.EdmBf_ShowSelected);
                    

                /*}*/

                EdmBomColumn[] ppoColumns = null;
                bomView.GetColumns(out ppoColumns);

                int j2 = 0;
                int arrSize2 = ppoColumns.Length;

                EdmBomColumnType ebctGuidConfCostr = default(EdmBomColumnType);
                int iGuidConfCostrID = 0;

                EdmBomColumnType ebctConfig = default(EdmBomColumnType);
                int iConfigID = 0;

                EdmBomColumnType ebctQty = default(EdmBomColumnType);
                int iQtyID = 0;

                EdmBomColumnType ebctFamiglia1_Prefix = default(EdmBomColumnType);
                int iFamiglia1_PrefixID = 0;

                EdmBomColumnType ebctFamiglia2_Prefix = default(EdmBomColumnType);
                int iFamiglia2_PrefixID = 0;

                EdmBomColumnType ebctFamiglia3_Prefix = default(EdmBomColumnType);
                int iFamiglia3_PrefixID = 0;

                EdmBomColumnType ebctSup_Gommata = default(EdmBomColumnType);
                int iSup_GommataID = 0;

                EdmBomColumnType ebctPeso = default(EdmBomColumnType);
                int iPesoID = 0;

                EdmBomColumnType ebctLg = default(EdmBomColumnType);
                int iLgID = 0;

                

                EdmBomColumnType ebctVersione = default(EdmBomColumnType);
                int iVersioneID = 0;

                EdmBomColumnType ebctID = default(EdmBomColumnType);
                int iIDID = 0;

                EdmBomColumnType ebctDBPATH = default(EdmBomColumnType);
                int iDBPATHID = 0;

                EdmBomColumnType ebctDED_FILE = default(EdmBomColumnType);
                int iDED_FILEID = 0;


                

                bool lFoundConf;
                lFoundConf = false;

                bool lFoundQty;
                lFoundQty = false;

                bool lFoundFamiglia1_Prefix;
                lFoundFamiglia1_Prefix = false;

                bool lFoundFamiglia2_Prefix;
                lFoundFamiglia2_Prefix = false;

                bool lFoundFamiglia3_Prefix;
                lFoundFamiglia3_Prefix = false;

                bool lFoundLg;
                lFoundLg = false;

                bool lFoundSup_Gommata;
                lFoundSup_Gommata = false;

                bool lFoundPeso;
                lFoundPeso = false;

                bool lFoundGuidConfCostr;
                lFoundGuidConfCostr = false;

                bool lFoundVersione;
                lFoundVersione = false;

                bool lFoundID;
                lFoundID = false;

                bool lFoundDBPATH;
                lFoundDBPATH = false;

                bool lFoundDED_FILE;
                lFoundDED_FILE = false;


                while (j2 < arrSize2)
                {

                    //MessageBox.Show(ppoColumns[j2].mbsCaption);

                    if (ppoColumns[j2].mbsCaption == "Versione")
                    {


                        lFoundVersione = true;
                        iVersioneID = ppoColumns[j2].mlVariableID;
                        ebctVersione = ppoColumns[j2].meType;




                    }

                    if (ppoColumns[j2].mbsCaption == "ID")
                    {


                        lFoundID = true;
                        iIDID = ppoColumns[j2].mlVariableID;
                        ebctID = ppoColumns[j2].meType;

                    }

                    

                    if (ppoColumns[j2].mbsCaption == "Configuration")
                    {


                        lFoundConf = true;
                        iConfigID = ppoColumns[j2].mlVariableID;
                        ebctConfig = ppoColumns[j2].meType;


                    }


                    if (ppoColumns[j2].mbsCaption == "ICMRefBOMGUID")
                    {


                        lFoundGuidConfCostr = true;
                        iGuidConfCostrID = ppoColumns[j2].mlVariableID;
                        ebctGuidConfCostr = ppoColumns[j2].meType;


                    }


                    if (ppoColumns[j2].mbsCaption == "Qty")
                    {


                        lFoundQty = true;
                        iQtyID = ppoColumns[j2].mlVariableID;
                        ebctQty = ppoColumns[j2].meType;


                    }

                    if (ppoColumns[j2].mbsCaption.ToUpper() == "FAMIGLIA1_PREFIX")
                    {


                        lFoundFamiglia1_Prefix = true;
                        iFamiglia1_PrefixID = ppoColumns[j2].mlVariableID;
                        ebctFamiglia1_Prefix = ppoColumns[j2].meType;

                    }

                    if (ppoColumns[j2].mbsCaption.ToUpper() == "FAMIGLIA2_PREFIX")
                    {


                        lFoundFamiglia2_Prefix = true;
                        iFamiglia2_PrefixID = ppoColumns[j2].mlVariableID;
                        ebctFamiglia2_Prefix = ppoColumns[j2].meType;

                    }

                    if (ppoColumns[j2].mbsCaption.ToUpper() == "FAMIGLIA3_PREFIX")
                    {

                        lFoundFamiglia3_Prefix = true;
                        iFamiglia3_PrefixID = ppoColumns[j2].mlVariableID;
                        ebctFamiglia3_Prefix = ppoColumns[j2].meType;

                    }

                    if (ppoColumns[j2].mbsCaption.ToUpper() == "LG")
                    {


                        lFoundLg = true;
                        iLgID = ppoColumns[j2].mlVariableID;
                        ebctLg = ppoColumns[j2].meType;

                    }


                    if (ppoColumns[j2].mbsCaption.ToUpper() == "SUP_GOMMATA")
                    {


                        lFoundSup_Gommata = true;
                        iSup_GommataID = ppoColumns[j2].mlVariableID;
                        ebctSup_Gommata = ppoColumns[j2].meType;

                    }

                    if (ppoColumns[j2].mbsCaption.ToUpper() == "PESO")
                    {


                        lFoundPeso = true;
                        iPesoID = ppoColumns[j2].mlVariableID;
                        ebctPeso = ppoColumns[j2].meType;

                    }

                    if (ppoColumns[j2].mbsCaption.ToUpper() == "DBPATH")
                    {


                        lFoundDBPATH = true;
                        iDBPATHID = ppoColumns[j2].mlVariableID;
                        ebctDBPATH = ppoColumns[j2].meType;

                    }


                    if (ppoColumns[j2].mbsCaption.ToUpper() == "DED_FILE")
                    {


                        lFoundDED_FILE = true;
                        iDED_FILEID = ppoColumns[j2].mlVariableID;
                        ebctDED_FILE = ppoColumns[j2].meType;

                    }


                    j2++;

                }

                               
                

                if (!lFoundConf)
                {

                    throw new ApplicationException("Colonna Configurazione non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundQty)
                {

                    throw new ApplicationException("Colonna Qty non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundFamiglia1_Prefix)
                {

                    throw new ApplicationException("Colonna Famiglia1_Prefix non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundFamiglia2_Prefix)
                {

                    throw new ApplicationException("Colonna Famiglia2_Prefix non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundFamiglia3_Prefix)
                {

                    throw new ApplicationException("Colonna Famiglia3_Prefix non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundGuidConfCostr)
                {

                    throw new ApplicationException("Colonna Guid Configurazione Costruttiva non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundVersione)
                {

                    throw new ApplicationException("Colonna Versione non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundID)
                {

                    throw new ApplicationException("Colonna ID non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundDBPATH)
                {

                    throw new ApplicationException("Colonna DBPATH non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }

                if (!lFoundDED_FILE)
                {

                    throw new ApplicationException("Colonna DED_FILE non trovata nella BOM: " + cTipoDistinta + " del file: " + cFileName);

                }




                object[] ppoRows = null;
                IEdmBomCell ppoRow = default(IEdmBomCell);
                bomView.GetRows(out ppoRows);
                int i = 0;
                int arrSize = ppoRows.Length;
                
                string str = "";

                bool bNonCodificato;

                //MessageBox.Show(arrSize.ToString());
              
                while (i < arrSize)
                {

                    bNonCodificato = false;

                    tmp_DEDIDP = "";
                    tmp_DEDREVP = "";
                    tmp_DEDIDC = "";
                    tmp_DEDREVC = "";
                    tmp_QTA = "";
                    tmp_FAMIGLIA1_PREFIX = "";
                    tmp_FAMIGLIA2_PREFIX = "";
                    tmp_FAMIGLIA3_PREFIX = "";
                    tmp_LG = "";
                    tmp_SUP_GOMMATA = "";
                    tmp_PESO = "";
                    bThis = true;


                    ppoRow = (IEdmBomCell)ppoRows[i];

                    if (ppoRow.GetTreeLevel() == 0)
                    {

                        //MessageBox.Show("Sbianca DEDLINEAR");
                        
                        tmp_DEDLinear = "";
                        tmp_DEDMass = "";
                        newIdToTake = 0;
                        newVersionToTake = 0;

                    }


                    if (ppoRow.GetTreeLevel() == 0)
                    {
                        sFaiAcquistaLivello0 = "";

                        /* Insert DEDANAG */

                        string query = "IF NOT EXISTS (SELECT 1 FROM [dbo].[SWANAG] WHERE SessionId = '" + currentSessionGuid + "' AND DEDID = <@@@!!èà@@DEDID> AND DEDREV = <@@@!!èà@@DEDREV>) " +
                                       "INSERT INTO [dbo].[SWANAG] " +
                                       "([SessionID]" +
                                       ",[DEDID]" +
                                       ",[DEDREV]" +
                                       ",[CATEGORIA1]" +
                                       ",[CATEGORIA2]" +
                                       ",[CATEGORIA3]" +
                                       ",[CATEGORIA1_PREFIX]" +
                                       ",[CATEGORIA2_PREFIX]" +
                                       ",[CATEGORIA3_PREFIX]" +
                                       ",[FAMIGLIA1]" +
                                       ",[FAMIGLIA2]" +
                                       ",[FAMIGLIA3]" +
                                       ",[FAMIGLIA1_PREFIX]" +
                                       ",[FAMIGLIA2_PREFIX]" +
                                       ",[FAMIGLIA3_PREFIX]" +
                                       ",[COMMESSA]" +
                                       ",[DEDDATE]" +
                                       ",[DBPATH]" +
                                       ",[DED_COD]" +
                                       ",[DED_DIS]" +
                                       ",[DED_FILE]" +
                                       ",[DEDREVDATE]" +
                                       ",[DEDREVDESC]" +
                                       ",[DEDREVUSER]" +
                                       ",[DEDSTATEID]" +
                                       ",[DEDDESC]" +
                                       ",[LG]" +
                                       ",[MATERIALE]" +
                                       ",[NOTA_DI_TAGLIO]" +
                                       ",[PESO]" +
                                       ",[SUP_GOMMATA]" +
                                       ",[TIPOLOGIA]" +
                                       ",[TRATT_TERM]" +
                                       ",[DEDSTATEID1]" +
                                       ",[ITEM]" +
                                       ",[POTENZA]" +
                                       ",[N_MOTORI]" +
                                       ",[SOTTOCOMMESSA]" +
                                       ",[Standard_DIN]" +
                                       ",[Standard_ISO]" +
                                       ",[Standard_UNI]" +
                                       ",[MPTH]" +
                                       ",[Produttore]" +
                                       ",[shmetal_AreaContorno_mm2]" +
                                       ",[shmetal_L1_Contorno]" +
                                       ",[shmetal_L2_Contorno]" +
                                       ",[shmetal_Piegature]" +
                                       ",[shmetal_RaggioDiPiegatura]" +
                                       ",[shmetal_Sp_Lamiera]" +
                                       ",[Designazione]" +
                                       ",[DesignazioneGeometrica]" +
                                       ",[DesignazioneGeometricaEN]" +
                                       ",[DesignazioneGeometricaENG]" +
                                       ",[DesignazioneGeometricaITA]" +
                                       ",[IngombroX]" +
                                       ",[IngombroY]" +
                                       ",[IngombroZ]" +
                                       ",[LargMacchina]" +
                                       ",[LungMacchina]" +
                                       ",[CATEGORIA4]" +
                                       ",[CATEGORIA4_PREFIX]" +
                                       ",[CodiceProduttore]" +
                                       ",[CATEGORIA0]" +
                                       ",[CATEGORIA0_PREFIX]" +
                                       ",[FaiAcquista]" +
                                       ",[DescTecnicaITA]" +
                                       ",[DescTecnicaENG]" +
                                       ",[DescCommercialeITA]" +
                                       ",[DescCommercialeENG]" +
                                       ",[TrattFinitura]" +
                                       ",[TrattGalvanico]" +
                                       ",[TrattProtezione]" +
                                       ",[TrattSuperficiale]" +
                                       ",[Configurazione]" +
                                       ",[DEDLinear]" +
                                       ",[DEDMass]" +
                                       ",[DateIns]" +
                                       ",[DateUpd])" +
                                       "VALUES" +
                                       "('" + currentSessionGuid + "'" +
                                       ",<@@@!!èà@@DEDID>" +
                                       ",<@@@!!èà@@DEDREV>" +
                                       ",<@@@!!èà@@CATEGORIA1>" +
                                       ",<@@@!!èà@@CATEGORIA2>" +
                                       ",<@@@!!èà@@CATEGORIA3>" +
                                       ",<@@@!!èà@@CATEGORIA1_PREFIX>" +
                                       ",<@@@!!èà@@CATEGORIA2_PREFIX>" +
                                       ",<@@@!!èà@@CATEGORIA3_PREFIX>" +
                                       ",<@@@!!èà@@FAMIGLIA1>" +
                                       ",<@@@!!èà@@FAMIGLIA2>" +
                                       ",<@@@!!èà@@FAMIGLIA3>" +
                                       ",<@@@!!èà@@FAMIGLIA1_PREFIX>" +
                                       ",<@@@!!èà@@FAMIGLIA2_PREFIX>" +
                                       ",<@@@!!èà@@FAMIGLIA3_PREFIX>" +
                                       ",<@@@!!èà@@COMMESSA>" +
                                       ",<@@@!!èà@@DEDDATE>" +
                                       ",<@@@!!èà@@DBPATH>" +
                                       ",<@@@!!èà@@DED_COD>" +
                                       ",<@@@!!èà@@DED_DIS>" +
                                       ",<@@@!!èà@@DED_FILE>" +
                                       ",<@@@!!èà@@DEDREVDATE>" +
                                       ",<@@@!!èà@@DEDREVDESC>" +
                                       ",<@@@!!èà@@DEDREVUSER>" +
                                       ",<@@@!!èà@@DEDSTATEID>" +
                                       ",<@@@!!èà@@DEDDESC>" +
                                       ",<@@@!!èà@@LG>" +
                                       ",<@@@!!èà@@MATERIALE>" +
                                       ",<@@@!!èà@@NOTA_DI_TAGLIO>" +
                                       ",<@@@!!èà@@PESO>" +
                                       ",<@@@!!èà@@SUP_GOMMATA>" +
                                       ",''" +  //<@TIPOLOGIA>
                                       ",<@@@!!èà@@TRATT_TERM>" +
                                       ",''" + //<@DEDSTATEID1>
                                       ",<@@@!!èà@@ITEM>" +
                                       ",<@@@!!èà@@POTENZA>" +
                                       ",<@@@!!èà@@N_MOTORI>" +
                                       ",<@@@!!èà@@SOTTOCOMMESSA>" +
                                       ",<@@@!!èà@@Standard_DIN>" +
                                       ",<@@@!!èà@@Standard_ISO>" +
                                       ",<@@@!!èà@@Standard_UNI>" +
                                       ",<@@@!!èà@@MPTH>" +
                                       ",<@@@!!èà@@Produttore>" +
                                       ",<@@@!!èà@@shmetal_AreaContorno_mm2>" +
                                       ",<@@@!!èà@@shmetal_L1_Contorno>" +
                                       ",<@@@!!èà@@shmetal_L2_Contorno>" +
                                       ",<@@@!!èà@@shmetal_Piegature>" +
                                       ",<@@@!!èà@@shmetal_RaggioDiPiegatura>" +
                                       ",<@@@!!èà@@shmetal_Sp_Lamiera>" +
                                       ",<@@@!!èà@@Designazione>" +
                                       ",<@@@!!èà@@DesignazioneGeometrica>" +
                                       ",<@@@!!èà@@DesignazioneGeometricaEN>" +
                                       ",<@@@!!èà@@DesignazioneGeometricaENG>" +
                                       ",<@@@!!èà@@DesignazioneGeometricaITA>" +
                                       ",<@@@!!èà@@IngombroX>" +
                                       ",<@@@!!èà@@IngombroY>" +
                                       ",<@@@!!èà@@IngombroZ>" +
                                       ",<@@@!!èà@@LargMacchina>" +
                                       ",<@@@!!èà@@LungMacchina>" +
                                       ",<@@@!!èà@@CATEGORIA4>" +
                                       ",<@@@!!èà@@CATEGORIA4_PREFIX>" +
                                       ",<@@@!!èà@@CodiceProduttore>" +
                                       ",<@@@!!èà@@CATEGORIA0>" +
                                       ",<@@@!!èà@@CATEGORIA0_PREFIX>" +
                                       ",<@@@!!èà@@FaiAcquista>" +
                                       ",<@@@!!èà@@DescTecnicaITA>" +
                                       ",<@@@!!èà@@DescTecnicaENG>" +
                                       ",<@@@!!èà@@DescCommercialeITA>" +
                                       ",<@@@!!èà@@DescCommercialeENG>" +
                                       ",<@@@!!èà@@TrattFinitura>" +
                                       ",<@@@!!èà@@TrattGalvanico>" +
                                       ",<@@@!!èà@@TrattProtezione>" +
                                       ",<@@@!!èà@@TrattSuperficiale>" +
                                       ",<@@@!!èà@@Configurazione>" +
                                       ",<@@@!!èà@@DEDLinear>" +
                                       ",<@@@!!èà@@DEDMass>" +
                                       ",GETDATE()" +
                                       ",GETDATE())";



                        int j = 0;
                        str = "";

                        descTecnicaITA = "";
                        descTecnicaENG = "";

                        while (j < arrSize2)
                        {


                            object poValue;
                            object poComputedValue;
                            string pbsConfiguration;
                            bool pbReadOnly;


                            ppoRow.GetVar(ppoColumns[j].mlVariableID
                                            , ppoColumns[j].meType
                                            , out poValue
                                            , out poComputedValue
                                            , out pbsConfiguration
                                            , out pbReadOnly);


                            string cParValue = poValue.ToString();



                            if (lFields.Contains(ppoColumns[j].mbsCaption))
                            {

                                //MessageBox.Show("@" + ppoColumns[j].mbsCaption + " ----- " + cParValue);

                                //MessageBox.Show(ppoColumns[j].meType.ToString());


                                if (ppoColumns[j].mbsCaption == "DEDID")
                                {

                                    if (cParValue.Trim() == "" || cParValue.Trim() == "-" || cParValue.Trim() == "--")
                                    {

                                        iTempContRev++;
                                        cParValue = cTempCodice + iTempContRev.ToString();

                                        //Debugger.Launch();

                                        if (cNonCodificati == "")
                                            cNonCodificati = cFileName;
                                        else
                                            cNonCodificati += (char)(10) + cFileName;

                                        lStop = true;

                                        bNonCodificato = true;
                                        bNonCodificatoPar = true;

                                        object poValueTemp;
                                        object poComputedValueTemp;
                                        string pbsConfigurationTemp;
                                        bool pbReadOnlyTemp;


                                        ppoRow.GetVar(iDBPATHID
                                                    , ebctDBPATH
                                                    , out poValueTemp
                                                    , out poComputedValueTemp
                                                    , out pbsConfigurationTemp
                                                    , out pbReadOnlyTemp);


                                        string cDBPATH = poValueTemp.ToString();


                                        ppoRow.GetVar(iDED_FILEID
                                                    , ebctDED_FILE
                                                    , out poValueTemp
                                                    , out poComputedValueTemp
                                                    , out pbsConfigurationTemp
                                                    , out pbReadOnlyTemp);


                                        string cDED_FILE = poValueTemp.ToString();


                                        WriteLog("Attenzione: Codice mancante per " + cDBPATH + " --- " + cDED_FILE + ". Articolo non importato", TraceEventType.Warning);



                                    }



                                }

                                if (ppoColumns[j].mbsCaption == "DEDREV")
                                {

                                    if (cParValue.Trim() == "")
                                    {
                                        cParValue = "00";
                                    }

                                }


                                if (ppoColumns[j].mbsCaption == "DEDLinear")
                                {

                                    //Debugger.Launch();

                                    //MessageBox.Show("DEDLINEAR = " + cParValue + "sDedID = " +sDEDID);

                                    tmp_DEDLinear = cParValue;

                                }

                                if (ppoColumns[j].mbsCaption == "DEDMass")
                                {

                                    tmp_DEDMass = cParValue;

                                }


                                if (ppoColumns[j].mbsCaption == "FaiAcquista")
                                {
                                    if (cParValue.ToUpper() != "FAI" && cParValue.ToUpper() != "ACQUISTA")
                                    {
                                        

                                        throw new ApplicationException("Custom Property FaiAcquista con valore errato in file: " + cFileName);

                                    }

                                    /*
                                    if (cParValue.Trim() == "")
                                    {

                                        if (cTipoDistinta == "DistintaAssiemePerArca")
                                            cParValue = "Fai";
                                        else if (cTipoDistinta == "DistintaPartePerArca")
                                            cParValue = "Acquista";

                                    }
                                    */

                                    sFaiAcquistaLivello0 = cParValue;

                                }

                                if (ppoColumns[j].mbsCaption == "TRATT_TERMICO")
                                {

                                    query = query.Replace("<@@@!!èà@@" + "TRATT_TERM" + ">", "'" + cParValue.Replace("'", "''") + "'");
                                }
                                else
                                    query = query.Replace("<@@@!!èà@@" + ppoColumns[j].mbsCaption + ">", "'" + cParValue.Replace("'", "''") + "'");

                                //command.Parameters.AddWithValue("@" + ppoColumns[j].mbsCaption, cParValue);

                                if (ppoColumns[j].mbsCaption == "DescTecnicaITA")
                                    descTecnicaITA = cParValue;

                                if (ppoColumns[j].mbsCaption == "DescTecnicaENG")
                                    descTecnicaENG = cParValue;

                                

                                if (ppoColumns[j].mbsCaption == "DEDID")
                                {
                                    sDEDID = cParValue;
                                    sDEDIDP = cParValue;
                                }


                                if (ppoColumns[j].mbsCaption == "DEDREV")
                                {
                                    sDEDREV = cParValue;
                                    sDEDREVP = cParValue;
                                }

                                if (ppoColumns[j].mbsCaption == "DEDLinear")
                                {
                                    sDEDLinear = cParValue;
                                }

                                if (ppoColumns[j].mbsCaption == "DEDMass")
                                {
                                    sDEDMass = cParValue;
                                }



                            }


                            j++;

                        }

                        if (bNonCodificato)
                            return;

                        query = query.Replace("<@@@!!èà@@" + "DEDDESC" + ">", "'" + descTecnicaITA.Replace("'", "''") + " --- " + descTecnicaENG.Replace("'", "''") + "'");

                        //MessageBox.Show(query);

                        WriteLog("Esporta " + sDEDID + "//" + sDEDREV + " --- " + descTecnicaITA);


                        //cache

                        cacheDictionary.Add(new Tuple<string, string>(cFileName, sConf), new Tuple<string, string, int>(sDEDID, sDEDREV, iPromosso));


                        WriteLog("Promosso ---> " + iPromosso.ToString());

                        if (!((iPromosso == 2) && cTipoDistinta == "DistintaAssiemePerArca"))
                        {


                            //TS.WriteLine(query);

                            SqlCommand command = new SqlCommand(query, cnn);
                            command.Transaction = transaction;

                            command.ExecuteNonQuery();


                        }


                    }

                    else if (ppoRow.GetTreeLevel() == 1)
                    {


                        /* se richiesto esporta solo un livello */
                        if ((!first) && bOnlyTop)
                        {

                            i++;
                            continue;

                        }

                        //MessageBox.Show(ppoRow.GetPathName());
                        if (cTipoDistinta == "DistintaAssiemePerArca")
                        {

                            bThis = true;

                          

                            object poValue;
                            object poComputedValue;
                            string pbsConfiguration;
                            bool pbReadOnly;
                            string sFileNameDocCostr;
                            string sVersione;
                            int iVersioneChild;
                            Boolean bConv;
                            string sID;
                            int iIDChild;
                            double dQty;
                            string sGuidConfCostr;
                            string sConfigurazioneCostruttiva;
                            string sUltimaRevisione;
                            bool bUltimaRevisione;

                            /* se l'assieme è Acquistato mi fermo */

                            if (sFaiAcquistaLivello0.ToUpper() == "ACQUISTA")
                            {
                                i++;
                                continue;
                            }

                            /* cerco la configurazione costruttiva */                            
                            

                            ppoRow.GetVar(iQtyID
                                          , ebctQty
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);

                            sQty = poValue.ToString();
                            

                            bConv = Double.TryParse(sQty, out dQty);

                            if (!bConv)
                            {

                                throw new ApplicationException("Errore in conversione quantità in BOM di: " + cFileName);

                            }


                            sFileNameDocCostr = "";
                            sGuidConfCostr = "";
                            sConfigurazioneCostruttiva = "";


                            ppoRow.GetVar(iGuidConfCostrID
                                          , ebctGuidConfCostr
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);


                            if (poValue.ToString().ToUpper() == "THIS")
                            {
                                bThis = true;
                                sFileNameDocCostr = ppoRow.GetPathName();
                                sGuidConfCostr = poValue.ToString();

                                /* prende configurazione corrente */
                                ppoRow.GetVar(iConfigID
                                            , ebctConfig
                                            , out poValue
                                            , out poComputedValue
                                            , out pbsConfiguration
                                            , out pbReadOnly);

                                sConfigurazioneCostruttiva = poValue.ToString();

                            }
                            else
                            {

                                //Debugger.Launch();

                                bThis = false; 
                                sFileNameDocCostr = "";
                                

                                sGuidConfCostr = poValue.ToString();

                                //MessageBox.Show(sGuidDocCostr);

                                //recupera il nomefile dal GUID

                                IEdmSearch9 Search = (IEdmSearch9)((IEdmVault21) vault).CreateSearch2();
                                if (Search != null)
                                {


                                    Search.FindFiles = true;
                                    Search.FindFolders = false;
                                    

                                    Search.AddVariable2("ICMBOMGUID", sGuidConfCostr);
                                    

                                    IEdmSearchResult5 SearchResult = Search.GetFirstResult();   
                                    while ((SearchResult != null))
                                    {

                                        int id;
                                        int parent_folder_id;

                                        IEdmObject5 pdmObject;
                                        IEdmFile5 pdmFile;

                                        id = SearchResult.ID;
                                                                                

                                        parent_folder_id = SearchResult.ParentFolderID;

                                        pdmObject = default(IEdmObject5);

                                        pdmObject = vault.GetObject(EdmObjectType.EdmObject_File, id);

                                        if (pdmObject != null)
                                        {

                                            pdmFile = (IEdmFile5)pdmObject;

                                           
                                            sFileNameDocCostr = pdmFile.GetLocalPath(parent_folder_id);

                                            newIdToTake = id;

                                            SqlCommand command2 = new SqlCommand("dbo.ICM_Conf_GetConfiUltVerSp", cnn);

                                            command2.CommandType = CommandType.StoredProcedure;
                                            command2.Transaction = transaction;

                                            //MessageBox.Show(iDocument.ToString() + " - " + sConf + " - " + iVersione.ToString());


                                            SqlParameter sqlParam = command2.Parameters.Add("@DocumentID", SqlDbType.Int);
                                            sqlParam.Direction = ParameterDirection.Input;
                                            sqlParam.Value = id;


                                            sqlParam = command2.Parameters.Add("@ICMRefBOMGUID", SqlDbType.VarChar, 200);
                                            sqlParam.Direction = ParameterDirection.Input;
                                            sqlParam.Value = sGuidConfCostr;

                                            sqlParam = command2.Parameters.Add("@ConfName", SqlDbType.VarChar, 200);
                                            sqlParam.Direction = ParameterDirection.Output;                                           
                                            

                                            sqlParam = new SqlParameter("@UltRevisionNo", SqlDbType.Int);
                                            //sqlParam.ParameterName = "@Result";
                                            //sqlParam.DbType = DbType.Boolean;
                                            sqlParam.Direction = ParameterDirection.Output;
                                            command2.Parameters.Add(sqlParam);

                                            command2.ExecuteNonQuery();

                                            sConfigurazioneCostruttiva = command2.Parameters["@ConfName"].Value.ToString();

                                            if (sConfigurazioneCostruttiva.Trim() == "" || sConfigurazioneCostruttiva == null)
                                            {

                                                throw new ApplicationException("Errore nel recuperare il nome della configurazione costruttiva nella BOM di " + cFileName);
                                            }


                                            sUltimaRevisione = command2.Parameters["@UltRevisionNo"].Value.ToString();

                                            if (sUltimaRevisione.Trim() == "" || sUltimaRevisione == null)
                                            {

                                                throw new ApplicationException("Errore nel recuperare l'ultima versione della configurazione costruttiva nella BOM di " + cFileName);
                                            }

                                            bUltimaRevisione = Int32.TryParse(sUltimaRevisione, out newVersionToTake);

                                            if (!bUltimaRevisione)
                                            {

                                                throw new ApplicationException("Errore nel recuperare l'ultima versione della configurazione costruttiva nella BOM di " + cFileName);

                                            }

                                            // prendo l'ultima versione
                                            //object[] ppoRetVars = null;
                                            //string[] ppoRetConfs = null;
                                            //EdmGetVarData poRetDat = new EdmGetVarData();

                                            //IEdmEnumeratorVariable7 enumVar;

                                            //enumVar = (IEdmEnumeratorVariable7)pdmFile.GetEnumeratorVariable();
                                            //enumVar.GetVersionVars(0, parent_folder_id, out ppoRetVars, out ppoRetConfs, ref poRetDat);


                                            // se documento costruttivo diverso prende l'ultima versione
                                            //newVersionToTake = poRetDat.mlVersion;

                                        }

                                        break;
                                    }


                                }


                            }

                            if (sFileNameDocCostr == null || sFileNameDocCostr.Trim() == "")
                            {

                                throw new ApplicationException("File costruttivo non trovato nella BOM del file: " + cFileName + " - GUID Documento = " + sGuidConfCostr);

                            }


                            /* Versione */
                            ppoRow.GetVar(iVersioneID
                                          , ebctVersione
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);


                            sVersione = poValue.ToString();

                            bConv = Int32.TryParse(sVersione, out iVersioneChild);

                            if (!bConv)
                            {

                                throw new ApplicationException("Versione non trovata nella BOM del file: " + cFileName);

                            }

                            /* ID */

                            ppoRow.GetVar(iIDID
                                          , ebctID
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);


                            sID = poValue.ToString();

                            bConv = Int32.TryParse(sID, out iIDChild);

                            if (!bConv)
                            {

                                throw new ApplicationException("ID non trovato nella BOM del file: " + cFileName);

                            }

                            //MessageBox.Show(sFileNameDocCostr);

                            if (!bThis)
                            {

                                iIDChild = newIdToTake;
                                iVersioneChild = newVersionToTake;

                               //MessageBox.Show("New version to take: " + newVersionToTake.ToString());


                            }

                            iRetPromosso = 0;

                            WriteLog("---------------------------------");
                            WriteLog("Child ID: " + iIDChild.ToString());
                            WriteLog("Child FileName: " + sFileNameDocCostr);
                            WriteLog("Child Conf: " + sConfigurazioneCostruttiva);
                            WriteLog("---------------------------------");

                            bool bGetNonCodificato;

                            if (iPromosso == 2)
                                insertSW_ANAG_BOM(iIDChild, sFileNameDocCostr, iVersioneChild, sConfigurazioneCostruttiva, out sDEDIDC, out sDEDREVC, false, true, sDEDIDPromosso, sDEDREVPromosso, dQty, out iRetPromosso, out bGetNonCodificato, bOnlyTop);                                
                            else
                                insertSW_ANAG_BOM(iIDChild, sFileNameDocCostr, iVersioneChild, sConfigurazioneCostruttiva, out sDEDIDC, out sDEDREVC, false, false, sDEDIDP, sDEDREVP, 1, out iRetPromosso, out bGetNonCodificato, bOnlyTop);

                            if (bGetNonCodificato)
                            {
                                i++;
                                continue;
                            }

                            if ((sDEDIDP == "") ||
                                 (sDEDREVP == "") ||
                                 (sDEDIDC == "") ||
                                 (sDEDREVC == ""))
                            {

                                throw new ApplicationException("Riferimenti padre e figlio non compilati");

                            }

                            tmp_DEDIDP = sDEDIDP;
                            tmp_DEDREVP = sDEDREVP;
                            tmp_DEDIDC = sDEDIDC;
                            tmp_DEDREVC = sDEDREVC;
                            tmp_QTA = sQty;

                            if (iPromosso == 2)
                            {
                                tmp_DEDIDP = sDEDIDPromosso;
                                tmp_DEDREVP = sDEDREVPromosso;
                                tmp_QTA = (dQty * dQtyPromosso).ToString();
                            }

                            ppoRow.GetVar(iFamiglia1_PrefixID
                                          , ebctFamiglia1_Prefix
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);


                            tmp_FAMIGLIA1_PREFIX = poValue.ToString();

                            ppoRow.GetVar(iFamiglia2_PrefixID
                                        , ebctFamiglia2_Prefix
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);


                            tmp_FAMIGLIA2_PREFIX = poValue.ToString();


                            ppoRow.GetVar(iFamiglia3_PrefixID
                                        , ebctFamiglia3_Prefix
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);


                            tmp_FAMIGLIA3_PREFIX = poValue.ToString();

                            ppoRow.GetVar(iLgID
                                        , ebctLg
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);


                            tmp_LG = poValue.ToString();

                            ppoRow.GetVar(iSup_GommataID
                                        , ebctSup_Gommata
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);


                            tmp_SUP_GOMMATA = poValue.ToString();

                            ppoRow.GetVar(iPesoID
                                        , ebctPeso
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);


                            tmp_PESO = poValue.ToString();




                            itmp_Consumo += 1;
                            string stmp_Consumo = itmp_Consumo.ToString();

                            string query =
                            "IF NOT EXISTS (SELECT 1 FROM [dbo].[SWBOM] WHERE " +
                            "[SessionID] = '" + currentSessionGuid + "' AND " +
                            "[DEDIDP] = <@@@!!èà@@DEDIDP> AND " +
                            "[DEDREVP] = <@@@!!èà@@DEDREVP> AND " +
                            "[DEDIDC] = <@@@!!èà@@DEDIDC> AND " +
                            "[DEDREVC] = <@@@!!èà@@DEDREVC>) " +
                            "INSERT INTO [dbo].[SWBOM] " +
                            "([SessionID]" +
                            ",[DEDIDP]" +
                            ",[DEDREVP]" +
                            ",[DEDIDC]" +
                            ",[DEDREVC]" +
                            ",[QTA]" +
                            ",[FAMIGLIA1_PREFIX]" +
                            ",[FAMIGLIA2_PREFIX]" +
                            ",[FAMIGLIA3_PREFIX]" +
                            ",[DateIns]" +
                            ",[DateUpd])" +
                            "VALUES" +
                            "('" + currentSessionGuid + "'" +
                            ",<@@@!!èà@@DEDIDP>" +
                            ",<@@@!!èà@@DEDREVP>" +
                            ",<@@@!!èà@@DEDIDC>" +
                            ",<@@@!!èà@@DEDREVC>" +
                            ",<@@@!!èà@@QTA>" +
                            ",<@@@!!èà@@FAMIGLIA1_PREFIX>" +
                            ",<@@@!!èà@@FAMIGLIA2_PREFIX>" +
                            ",<@@@!!èà@@FAMIGLIA3_PREFIX>" +
                            ",GETDATE()" +
                            ",GETDATE()" +
                            ") ELSE UPDATE [dbo].[SWBOM] SET [QTA] = [QTA] + <@@@!!èà@@QTA>,DateUpd = GETDATE() WHERE " +
                            "[SessionID] = '" + currentSessionGuid + "' AND " +
                            "[DEDIDP] = <@@@!!èà@@DEDIDP> AND " +
                            "[DEDREVP] = <@@@!!èà@@DEDREVP> AND " +
                            "[DEDIDC] = <@@@!!èà@@DEDIDC> AND " +
                            "[DEDREVC] = <@@@!!èà@@DEDREVC> ";


                            
                            query = query.Replace("<@@@!!èà@@DEDIDP>", "'" + tmp_DEDIDP.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@DEDREVP>", "'" + tmp_DEDREVP.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@DEDIDC>", "'" + tmp_DEDIDC.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@DEDREVC>", "'" + tmp_DEDREVC.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@QTA>", "'" + tmp_QTA.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@FAMIGLIA1_PREFIX>", "'" + tmp_FAMIGLIA1_PREFIX.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@FAMIGLIA2_PREFIX>", "'" + tmp_FAMIGLIA2_PREFIX.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@FAMIGLIA3_PREFIX>", "'" + tmp_FAMIGLIA3_PREFIX.Replace("'", "''") + "'");



                            //Debugger.Launch();

                            if (!(iRetPromosso == 2))
                            {


                                SqlCommand command = new SqlCommand(query, cnn);
                                command.Transaction = transaction;

                                //TS.WriteLine(query);

                                command.ExecuteNonQuery();

                            }


                        }
                        else if (cTipoDistinta == "DistintaPartePerArca")
                        {

                            /* livello 1 di DistintaPartePerArca: sono su un elemento di CutList */

                            object poValue;
                            object poComputedValue;
                            string pbsConfiguration;
                            bool pbReadOnly;

                            bool bConv;
                            double dQtyCut;


                            /* se la parte è acquistata non importo il body */
                            if (sFaiAcquistaLivello0.ToUpper() == "ACQUISTA")
                            {
                                i++;
                                continue;
                            }



                            /* Insert DEDANAG per CutList*/

                            string query = "IF NOT EXISTS (SELECT 1 FROM [dbo].[SWANAG] WHERE SessionId = '" + currentSessionGuid + "' AND DEDID = <@@@!!èà@@DEDID> AND DEDREV = <@@@!!èà@@DEDREV>) " +
                                           "INSERT INTO [dbo].[SWANAG] " +
                                           "([SessionID]" +
                                           ",[DEDID]" +
                                           ",[DEDREV]" +
                                           ",[CATEGORIA1]" +
                                           ",[CATEGORIA2]" +
                                           ",[CATEGORIA3]" +
                                           ",[CATEGORIA1_PREFIX]" +
                                           ",[CATEGORIA2_PREFIX]" +
                                           ",[CATEGORIA3_PREFIX]" +
                                           ",[FAMIGLIA1]" +
                                           ",[FAMIGLIA2]" +
                                           ",[FAMIGLIA3]" +
                                           ",[FAMIGLIA1_PREFIX]" +
                                           ",[FAMIGLIA2_PREFIX]" +
                                           ",[FAMIGLIA3_PREFIX]" +
                                           ",[COMMESSA]" +
                                           ",[DEDDATE]" +
                                           ",[DBPATH]" +
                                           ",[DED_COD]" +
                                           ",[DED_DIS]" +
                                           ",[DED_FILE]" +
                                           ",[DEDREVDATE]" +
                                           ",[DEDREVDESC]" +
                                           ",[DEDREVUSER]" +
                                           ",[DEDSTATEID]" +
                                           ",[DEDDESC]" +
                                           ",[LG]" +
                                           ",[MATERIALE]" +
                                           ",[NOTA_DI_TAGLIO]" +
                                           ",[PESO]" +
                                           ",[SUP_GOMMATA]" +
                                           ",[TIPOLOGIA]" +
                                           ",[TRATT_TERM]" +
                                           ",[DEDSTATEID1]" +
                                           ",[ITEM]" +
                                           ",[POTENZA]" +
                                           ",[N_MOTORI]" +
                                           ",[SOTTOCOMMESSA]" +
                                           ",[Standard_DIN]" +
                                           ",[Standard_ISO]" +
                                           ",[Standard_UNI]" +
                                           ",[MPTH]" +
                                           ",[Produttore]" +
                                           ",[shmetal_AreaContorno_mm2]" +
                                           ",[shmetal_L1_Contorno]" +
                                           ",[shmetal_L2_Contorno]" +
                                           ",[shmetal_Piegature]" +
                                           ",[shmetal_RaggioDiPiegatura]" +
                                           ",[shmetal_Sp_Lamiera]" +
                                           ",[Designazione]" +
                                           ",[DesignazioneGeometrica]" +
                                           ",[DesignazioneGeometricaEN]" +
                                           ",[DesignazioneGeometricaENG]" +
                                           ",[DesignazioneGeometricaITA]" +
                                           ",[IngombroX]" +
                                           ",[IngombroY]" +
                                           ",[IngombroZ]" +
                                           ",[LargMacchina]" +
                                           ",[LungMacchina]" +
                                           ",[CATEGORIA4]" +
                                           ",[CATEGORIA4_PREFIX]" +
                                           ",[CodiceProduttore]" +
                                           ",[CATEGORIA0]" +
                                           ",[CATEGORIA0_PREFIX]" +
                                           ",[FaiAcquista]" +
                                           ",[DescTecnicaITA]" +
                                           ",[DescTecnicaENG]" +
                                           ",[DescCommercialeITA]" +
                                           ",[DescCommercialeENG]" +
                                           ",[TrattFinitura]" +
                                           ",[TrattGalvanico]" +
                                           ",[TrattProtezione]" +
                                           ",[TrattSuperficiale]" +
                                           ",[Configurazione]" +
                                           ",[DEDLinear]" +
                                           ",[DEDMass]" +
                                           ",[DateIns]" +
                                           ",[DateUpd]" +
                                           ")" +
                                           "VALUES" +
                                           "('" + currentSessionGuid + "'" +
                                           ",<@@@!!èà@@DEDID>" +
                                           ",<@@@!!èà@@DEDREV>" +
                                           ",<@@@!!èà@@CATEGORIA1>" +
                                           ",<@@@!!èà@@CATEGORIA2>" +
                                           ",<@@@!!èà@@CATEGORIA3>" +
                                           ",<@@@!!èà@@CATEGORIA1_PREFIX>" +
                                           ",<@@@!!èà@@CATEGORIA2_PREFIX>" +
                                           ",<@@@!!èà@@CATEGORIA3_PREFIX>" +
                                           ",<@@@!!èà@@FAMIGLIA1>" +
                                           ",<@@@!!èà@@FAMIGLIA2>" +
                                           ",<@@@!!èà@@FAMIGLIA3>" +
                                           ",<@@@!!èà@@FAMIGLIA1_PREFIX>" +
                                           ",<@@@!!èà@@FAMIGLIA2_PREFIX>" +
                                           ",<@@@!!èà@@FAMIGLIA3_PREFIX>" +
                                           ",<@@@!!èà@@COMMESSA>" +
                                           ",<@@@!!èà@@DEDDATE>" +
                                           ",<@@@!!èà@@DBPATH>" +
                                           ",<@@@!!èà@@DED_COD>" +
                                           ",<@@@!!èà@@DED_DIS>" +
                                           ",<@@@!!èà@@DED_FILE>" +
                                           ",<@@@!!èà@@DEDREVDATE>" +
                                           ",<@@@!!èà@@DEDREVDESC>" +
                                           ",<@@@!!èà@@DEDREVUSER>" +
                                           ",<@@@!!èà@@DEDSTATEID>" +
                                           ",<@@@!!èà@@DEDDESC>" +
                                           ",<@@@!!èà@@LG>" +
                                           ",<@@@!!èà@@MATERIALE>" +
                                           ",<@@@!!èà@@NOTA_DI_TAGLIO>" +
                                           ",<@@@!!èà@@PESO>" +
                                           ",<@@@!!èà@@SUP_GOMMATA>" +
                                           ",''" +  //<@TIPOLOGIA>
                                           ",<@@@!!èà@@TRATT_TERM>" +
                                           ",''" + //<@DEDSTATEID1>
                                           ",<@@@!!èà@@ITEM>" +
                                           ",<@@@!!èà@@POTENZA>" +
                                           ",<@@@!!èà@@N_MOTORI>" +
                                           ",<@@@!!èà@@SOTTOCOMMESSA>" +
                                           ",<@@@!!èà@@Standard_DIN>" +
                                           ",<@@@!!èà@@Standard_ISO>" +
                                           ",<@@@!!èà@@Standard_UNI>" +
                                           ",<@@@!!èà@@MPTH>" +
                                           ",<@@@!!èà@@Produttore>" +
                                           ",<@@@!!èà@@shmetal_AreaContorno_mm2>" +
                                           ",<@@@!!èà@@shmetal_L1_Contorno>" +
                                           ",<@@@!!èà@@shmetal_L2_Contorno>" +
                                           ",<@@@!!èà@@shmetal_Piegature>" +
                                           ",<@@@!!èà@@shmetal_RaggioDiPiegatura>" +
                                           ",<@@@!!èà@@shmetal_Sp_Lamiera>" +
                                           ",<@@@!!èà@@Designazione>" +
                                           ",<@@@!!èà@@DesignazioneGeometrica>" +
                                           ",<@@@!!èà@@DesignazioneGeometricaEN>" +
                                           ",<@@@!!èà@@DesignazioneGeometricaENG>" +
                                           ",<@@@!!èà@@DesignazioneGeometricaITA>" +
                                           ",<@@@!!èà@@IngombroX>" +
                                           ",<@@@!!èà@@IngombroY>" +
                                           ",<@@@!!èà@@IngombroZ>" +
                                           ",<@@@!!èà@@LargMacchina>" +
                                           ",<@@@!!èà@@LungMacchina>" +
                                           ",<@@@!!èà@@CATEGORIA4>" +
                                           ",<@@@!!èà@@CATEGORIA4_PREFIX>" +
                                           ",<@@@!!èà@@CodiceProduttore>" +
                                           ",<@@@!!èà@@CATEGORIA0>" +
                                           ",<@@@!!èà@@CATEGORIA0_PREFIX>" +
                                           ",'Acquista'" +     // Se importiamo il body, allora deve essere acquistato
                                           ",<@@@!!èà@@DescTecnicaITA>" +
                                           ",<@@@!!èà@@DescTecnicaENG>" +
                                           ",<@@@!!èà@@DescCommercialeITA>" +
                                           ",<@@@!!èà@@DescCommercialeENG>" +
                                           ",<@@@!!èà@@TrattFinitura>" +
                                           ",<@@@!!èà@@TrattGalvanico>" +
                                           ",<@@@!!èà@@TrattProtezione>" +
                                           ",<@@@!!èà@@TrattSuperficiale>" +
                                           ",<@@@!!èà@@Configurazione>" +
                                           ",<@@@!!èà@@DEDLinear>" +
                                           ",<@@@!!èà@@DEDMass>" +
                                           ",GETDATE()" +
                                           ",GETDATE()" +
                                           ")";



                            int j = 0;
                            str = "";

                            descTecnicaITA = "";
                            descTecnicaENG = "";

                            sFAMIGLIA1_PREFIX = "";
                            sFAMIGLIA2_PREFIX = "";
                            sFAMIGLIA3_PREFIX = "";

                            while (j < arrSize2)
                            {


                                //MessageBox.Show(ppoColumns[j].mbsCaption + " --- " + ppoColumns[j].mlFlags.ToString());
                                ppoRow.GetVar(ppoColumns[j].mlVariableID
                                                , ppoColumns[j].meType
                                                , out poValue
                                                , out poComputedValue
                                                , out pbsConfiguration
                                                , out pbReadOnly);


                                string cParValue = poValue.ToString();

                                if (lFields.Contains(ppoColumns[j].mbsCaption))
                                {

                                    //MessageBox.Show("@" + ppoColumns[j].mbsCaption + " ----- " + cParValue);
                                    //MessageBox.Show(ppoColumns[j].meType.ToString());


                                    if (ppoColumns[j].mbsCaption == "DEDID")
                                    {

                                        if (cParValue.Trim() == "" || cParValue.Trim() == "-" || cParValue.Trim() == "--")
                                        {
                                            iTempContRev++;
                                            cParValue = cTempCodice + iTempContRev.ToString();

                                            lStop = true;

                                            if (cNonCodificati == "")
                                                cNonCodificati = cFileName;
                                            else
                                                cNonCodificati += (char)(10) + cFileName + " (Body)";

                                            bNonCodificato = true;

                                            object poValueTemp;
                                            object poComputedValueTemp;
                                            string pbsConfigurationTemp;
                                            bool pbReadOnlyTemp;


                                            ppoRow.GetVar(iDBPATHID
                                                        , ebctDBPATH
                                                        , out poValueTemp
                                                        , out poComputedValueTemp
                                                        , out pbsConfigurationTemp
                                                        , out pbReadOnlyTemp);


                                            string cDBPATH = poValueTemp.ToString();


                                            ppoRow.GetVar(iDED_FILEID
                                                        , ebctDED_FILE
                                                        , out poValueTemp
                                                        , out poComputedValueTemp
                                                        , out pbsConfigurationTemp
                                                        , out pbReadOnlyTemp);


                                            string cDED_FILE = poValueTemp.ToString();


                                            WriteLog("Attenzione: Codice mancante per " + cDBPATH + " --- " + cDED_FILE + "(Body). Articolo non importato", TraceEventType.Warning);


                                        }


                                    }

                                    if (ppoColumns[j].mbsCaption == "DEDREV")
                                    {

                                        if (cParValue.Trim() == "")
                                        {
                                            cParValue = "00";
                                        }

                                    }

                                    if (ppoColumns[j].mbsCaption == "FaiAcquista")
                                    {
                                        cParValue = "Acquista";

                                    }


                                    if (ppoColumns[j].mbsCaption == "DEDLinear")
                                    {
                                        cParValue = sDEDLinear;

                                    }

                                    if (ppoColumns[j].mbsCaption == "DEDMass")
                                    {
                                        cParValue = sDEDMass;

                                    }


                                    if (ppoColumns[j].mbsCaption == "TRATT_TERMICO")
                                    {

                                        query = query.Replace("<@@@!!èà@@" + "TRATT_TERM" + ">", "'" + cParValue.Replace("'", "''") + "'");
                                    }
                                    else
                                        query = query.Replace("<@@@!!èà@@" + ppoColumns[j].mbsCaption + ">", "'" + cParValue.Replace("'", "''") + "'");

                                    //command.Parameters.AddWithValue("@" + ppoColumns[j].mbsCaption, cParValue);

                                    if (ppoColumns[j].mbsCaption == "FAMIGLIA1_PREFIX")
                                    {

                                        tmp_FAMIGLIA1_PREFIX = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "FAMIGLIA2_PREFIX")
                                    {

                                        tmp_FAMIGLIA2_PREFIX = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "FAMIGLIA3_PREFIX")
                                    {

                                        tmp_FAMIGLIA3_PREFIX = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "LG")
                                    {

                                        tmp_LG = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "SUP_GOMMATA")
                                    {

                                        tmp_SUP_GOMMATA = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "PESO")
                                    {

                                        tmp_PESO = cParValue;
                                    }


                                    if (ppoColumns[j].mbsCaption == "DescTecnicaITA")
                                        descTecnicaITA = cParValue;

                                    if (ppoColumns[j].mbsCaption == "DescTecnicaENG")
                                        descTecnicaENG = cParValue;


                                    if (ppoColumns[j].mbsCaption == "DEDID")
                                    {
                                        sDEDIDCCut = cParValue;

                                    }


                                    if (ppoColumns[j].mbsCaption == "DEDREV")
                                    {
                                        sDEDREVCCut = cParValue;

                                    }

                                    if (ppoColumns[j].mbsCaption == "FAMIGLIA1_PREFIX")
                                    {
                                        sFAMIGLIA1_PREFIX = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "FAMIGLIA2_PREFIX")
                                    {
                                        sFAMIGLIA2_PREFIX = cParValue;
                                    }

                                    if (ppoColumns[j].mbsCaption == "FAMIGLIA3_PREFIX")
                                    {
                                        sFAMIGLIA3_PREFIX = cParValue;
                                    }


                                }

                                j++;

                            }

                            if (bNonCodificato)
                                continue;

                            query = query.Replace("<@@@!!èà@@" + "DEDDESC" + ">", "'" + descTecnicaITA.Replace("'", "''") + " --- " + descTecnicaENG.Replace("'", "''") + "'");

                            WriteLog("Esporta " + sDEDIDCCut + "//" + sDEDREVCCut + " --- " + descTecnicaITA);

                            SqlCommand command = new SqlCommand(query, cnn);
                            command.Transaction = transaction;

                            //TS.WriteLine(query);

                            command.ExecuteNonQuery();

                            // Insert DEDDIST per CutList

                            ppoRow.GetVar(iQtyID
                                          , ebctQty
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);


                            sQtyCut = poValue.ToString();

                            

                            bConv = Double.TryParse(sQtyCut, out dQtyCut);

                            if (!bConv)
                            {

                                throw new ApplicationException("Errore in conversione quantità in BOM di: " + cFileName);

                            }



                            ppoRow.GetVar(iFamiglia1_PrefixID
                                          , ebctFamiglia1_Prefix
                                          , out poValue
                                          , out poComputedValue
                                          , out pbsConfiguration
                                          , out pbReadOnly);

                            sFamiglia1_Prefix = poValue.ToString();


                            ppoRow.GetVar(iFamiglia2_PrefixID
                                        , ebctFamiglia2_Prefix
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);

                            sFamiglia2_Prefix = poValue.ToString();


                            ppoRow.GetVar(iFamiglia3_PrefixID
                                        , ebctFamiglia3_Prefix
                                        , out poValue
                                        , out poComputedValue
                                        , out pbsConfiguration
                                        , out pbReadOnly);

                            sFamiglia3_Prefix = poValue.ToString();

                            tmp_DEDIDP = sDEDIDP;
                            tmp_DEDREVP = sDEDREVP;
                            tmp_DEDIDC = sDEDIDCCut;
                            tmp_DEDREVC = sDEDREVCCut;
                            tmp_QTA = sQtyCut;

                            if (iPromosso == 2)
                            {
                                tmp_DEDIDP = sDEDIDPromosso;
                                tmp_DEDREVP = sDEDREVPromosso;
                                tmp_QTA = (dQtyCut * dQtyPromosso).ToString();
                            }


                            itmp_Consumo += 1;
                            string stmp_Consumo = itmp_Consumo.ToString();


                            query = "IF NOT EXISTS (SELECT 1 FROM [dbo].[SWBOM] WHERE " +
                            "[SessionID] = '" + currentSessionGuid + "' AND " +
                            "[DEDIDP] = <@@@!!èà@@DEDIDP> AND " +
                            "[DEDREVP] = <@@@!!èà@@DEDREVP> AND " +
                            "[DEDIDC] = <@@@!!èà@@DEDIDC> AND " +
                            "[DEDREVC] = <@@@!!èà@@DEDREVC>) " +
                            "INSERT INTO [dbo].[SWBOM] " +
                            "([SessionID]" +
                            ",[DEDIDP]" +
                            ",[DEDREVP]" +
                            ",[DEDIDC]" +
                            ",[DEDREVC]" +
                            ",[QTA]" +
                            ",[FAMIGLIA1_PREFIX]" +
                            ",[FAMIGLIA2_PREFIX]" +
                            ",[FAMIGLIA3_PREFIX]" +
                            ",[DateIns]" +
                            ",[DateUpd]" +
                            ")" +
                            "VALUES" +
                            "('" + currentSessionGuid + "'" +
                            ",<@@@!!èà@@DEDIDP>" +
                            ",<@@@!!èà@@DEDREVP>" +
                            ",<@@@!!èà@@DEDIDC>" +
                            ",<@@@!!èà@@DEDREVC>" +
                            ",<@@@!!èà@@QTA>" +
                            ",<@@@!!èà@@FAMIGLIA1_PREFIX>" +
                            ",<@@@!!èà@@FAMIGLIA2_PREFIX>" +
                            ",<@@@!!èà@@FAMIGLIA3_PREFIX>" +
                            ",GETDATE()" +
                            ",GETDATE()" +
                            ") ELSE UPDATE [dbo].[SWBOM] SET [QTA] = [QTA] + <@@@!!èà@@QTA>, DateUpd = GETDATE() WHERE " +
                            "[SessionID] = '" + currentSessionGuid + "' AND " +
                            "[DEDIDP] = <@@@!!èà@@DEDIDP> AND " +
                            "[DEDREVP] = <@@@!!èà@@DEDREVP> AND " +
                            "[DEDIDC] = <@@@!!èà@@DEDIDC> AND " +
                            "[DEDREVC] = <@@@!!èà@@DEDREVC> ";


                            query = query.Replace("<@@@!!èà@@DEDIDP>", "'" + tmp_DEDIDP.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@DEDREVP>", "'" + tmp_DEDREVP.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@DEDIDC>", "'" + tmp_DEDIDC.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@DEDREVC>", "'" + tmp_DEDREVC.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@QTA>", "'" + tmp_QTA.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@FAMIGLIA1_PREFIX>", "'" + tmp_FAMIGLIA1_PREFIX.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@FAMIGLIA2_PREFIX>", "'" + tmp_FAMIGLIA2_PREFIX.Replace("'", "''") + "'");
                            query = query.Replace("<@@@!!èà@@FAMIGLIA3_PREFIX>", "'" + tmp_FAMIGLIA3_PREFIX.Replace("'", "''") + "'");

                            //TS.WriteLine(query);


                            command = new SqlCommand(query, cnn);
                            command.Transaction = transaction;

                            
                            command.ExecuteNonQuery();


                        }

                    }


                    i++;
                }

                if (first)
                {



                    string query = "UPDATE [dbo].[SWANAG] " +
                                   "SET DEDStart = 'S' " +
                                   "WHERE SessionID = '" + currentSessionGuid + "' AND DEDID =  <@@@!!èà@@DEDID> AND DEDREV =  <@@@!!èà@@DEDREV>";


                    query = query.Replace("<@@@!!èà@@DEDID>", "'" + sDEDID.Replace("'", "''") + "'");
                    query = query.Replace("<@@@!!èà@@DEDREV>", "'" + sDEDREV.Replace("'", "''") + "'");

                    SqlCommand command = new SqlCommand(query, cnn);
                    command.Transaction = transaction;

                    command.ExecuteNonQuery();

                }




            }


        }

        public int GetVersionLatestRevision(IEdmFile7 aFile)
        { 
        
            int iVersion;
            int iCurrentVersion;
            string sCurrentRevision;

            iVersion = 0;

            sCurrentRevision = aFile.CurrentRevision;
            iCurrentVersion = aFile.CurrentVersion;

            if (sCurrentRevision == null || sCurrentRevision.Trim() == "")
            {
                iVersion = iCurrentVersion;
                return iVersion;
            }
            else
            {

                IEdmEnumeratorVersion5 verEnum = default(IEdmEnumeratorVersion5);
                verEnum = (IEdmEnumeratorVersion5)aFile;


                for (int iCheckVersion = iCurrentVersion; iCheckVersion > 0; iCheckVersion--)
                {

                    //Get the version interface
                    try
                    {
                        IEdmVersion5 ver = default(IEdmVersion5);
                        ver = (IEdmVersion5)verEnum.GetVersion(iCheckVersion);

                        if (ver != null)
                        {
                            IEdmPos5 pos = default(IEdmPos5);
                            pos = ver.GetFirstRevisionPosition();

                            if (!pos.IsNull)
                            {
                                IEdmRevision5 rev = default(IEdmRevision5);
                                while (!pos.IsNull)
                                {
                                    rev = ver.GetNextRevision(pos);
                                    if (rev.Name == sCurrentRevision)
                                    {

                                        return iCheckVersion;

                                    }
                                }
                            }


                        }

                    }
                    catch (System.Runtime.InteropServices.COMException comEx)
                    {
                        switch (comEx.ErrorCode)
                        {
                            case (int)EdmResultErrorCodes_e.E_EDM_INVALID_REVISION_NUMBER:
                                continue;                                
                            default:
                                throw comEx;
                        }

                    }


                }

            }


            iVersion = iCurrentVersion;

            return iVersion;
        }

        //public const string LIC_KEY = "ICMSrl:swdocmgr_general-11785-02051-00064-33793-08629-34307-00007-21056-24258-41357-18249-06797-28051-02314-47107-52228-50244-12840-03222-47284-19773-22820-03364-19765-45513-14337-28772-52314-50378-25690-25696-1006,swdocmgr_previews-11785-02051-00064-33793-08629-34307-00007-31184-51130-14685-16798-60862-10393-19494-28674-50971-18073-37771-04381-09168-41361-24271-03364-19765-45513-14337-28772-52314-50378-25690-25696-1000,swdocmgr_dimxpert-11785-02051-00064-33793-08629-34307-00007-05336-27990-16960-35937-58127-19438-35807-26630-38432-63128-18458-01526-49106-45461-24086-03364-19765-45513-14337-28772-52314-50378-25690-25696-1000,swdocmgr_geometry-11785-02051-00064-33793-08629-34307-00007-57672-19923-32143-19233-37574-46535-36808-59394-38006-03797-02358-09615-15635-11338-24334-03364-19765-45513-14337-28772-52314-50378-25690-25696-1009,swdocmgr_xml-11785-02051-00064-33793-08629-34307-00007-57824-59519-37891-59911-49387-32794-32102-28672-44610-33796-16294-21731-07270-07352-23835-03364-19765-45513-14337-28772-52314-50378-25690-25696-1009,swdocmgr_tessellation-11785-02051-00064-33793-08629-34307-00007-28224-40350-42189-31440-29307-31095-63997-36870-42100-37430-42331-51585-17635-18238-24470-03364-19765-45513-14337-28772-52314-50378-25690-25696-1004";

        public const string LIC_KEY = "ICMSrl:swdocmgr_general-11785-02051-00064-01025-08692-34307-00007-43656-15919-20126-37704-62043-54742-44632-00001-31634-22177-09059-56494-36745-54482-24540-03364-19765-45513-14337-29284-51290-50890-25690-25696-1000,swdocmgr_dimxpert-11785-02051-00064-01025-08692-34307-00007-65368-42806-08313-35655-38023-12520-30955-63490-06177-12862-31120-31127-11099-16065-23496-03364-19765-45513-14337-29284-51290-50890-25690-25696-1002,swdocmgr_xml-11785-02051-00064-01025-08692-34307-00007-39488-61033-23506-47671-43675-22293-29650-32775-06267-45872-54819-31754-64197-47458-23066-03364-19765-45513-14337-29284-51290-50890-25690-25696-1003,swdocmgr_previews-11785-02051-00064-01025-08692-34307-00007-42424-61587-61271-04950-03954-00168-46435-63492-49142-21443-50705-31209-25258-32803-23481-03364-19765-45513-14337-29284-51290-50890-25690-25696-1004,swdocmgr_geometry-11785-02051-00064-01025-08692-34307-00007-51920-52413-02279-19114-52585-34621-16177-59392-02538-33316-25451-50730-02328-20070-23110-03364-19765-45513-14337-29284-51290-50890-25690-25696-1008,swdocmgr_tessellation-11785-02051-00064-01025-08692-34307-00007-48936-01685-27961-12898-30435-24102-21972-14339-40749-14339-12959-37749-15281-25764-24458-03364-19765-45513-14337-29284-51290-50890-25690-25696-1004";

        SwDM.SwDMApplication4 swDocMgr = null;
        SwDM.SwDMClassFactory swClassFact = null;

        public void IniziaAggiornamento(string sFileName, string sConfigurazioni, IEdmVault5 vault)
        {

            this.vault = vault;
            this.sFileName = sFileName;

            if (swDocMgr == null)
            {


                //Inizializzo un'istanza del document manager
                try
                {
                XFORMCOORDS:

                    swClassFact = new SwDM.SwDMClassFactory();

                    swDocMgr = (SwDM.SwDMApplication4)swClassFact.GetApplication(LIC_KEY);
                }
                catch (Exception ex)
                {

                    MessageBox.Show(ex.Message);
                    return;

                }

            }


            cacheFile = new List<string>();

            NavigateFile(sFileName, true);



        }

        public void NavigateFile(string cFileName, bool first)
        {
            SwDM.SwDMDocument19 swDoc19;
            SwDM.SwDMConfiguration12 config;
            SwDM.SwDMConfiguration15 config15;

            SwDM.SwDMConfiguration12 configCostr;

            if (cacheFile.Contains(cFileName))
                return;

            WriteLog("Elaborazione file: " + cFileName);

            //if (cFileName.ToUpper().IndexOf("D:\\LOCALVIEW\\ICM\\") > -1)
            //    return;

            string cFile;
            string cPathName;

            OpenFile(cFileName, out swDoc19, false, true);

            //Debugger.Launch();

            string[] vCustPropNameArr = null;
            string sCustPropStr = null;

            string[] vCfgNameArr = null;

            string sConfig;

            int i;

            bool lFound;
            bool lFoundFaiAcquista;
            bool lFoundGuid;
            bool lFoundCategoria3_prefix;

            string sConfigurazioneCostr;
            string sParentConf;

            string sFaiAcquista;

            bool lChangedGUID;

            sFaiAcquista = "";

            string sParteAssieme;

            string configurationGUID;

            if (cFileName.ToUpper().EndsWith(".SLDASM"))
                sParteAssieme = "Assieme";
            else if (cFileName.ToUpper().EndsWith(".SLDPRT"))
                sParteAssieme = "Parte";
            else
                throw new ApplicationException("ERROR: Il file " + cFileName + " non è nè parte nè assieme");

            SwDmCustomInfoType nPropType = 0;

            SwDMConfigurationMgr2 configMgr = default(SwDMConfigurationMgr2);
            configMgr = (SwDMConfigurationMgr2)swDoc19.ConfigurationManager;

            SwDMConfigurationError results = 0;

            vCfgNameArr = (string[])configMgr.GetConfigurationNames2(out results);

            if (results != SwDMConfigurationError.SwDMConfigurationError_None)
            {
                throw new ApplicationException("ERROR: Errore in ottenimento lista configurazioni per file: " + swDoc19.FullName);

            }

            

            for (i = 0; i < vCfgNameArr.Length; i++)
            {

                sConfig = vCfgNameArr[i];                

                config = default(SwDMConfiguration12);
                config = (SwDM.SwDMConfiguration12)configMgr.GetConfigurationByName(sConfig);

                if (config == null)
                {

                    throw new ApplicationException("ERROR: Errore in ottenimento configurazione " + sConfig + "per file: " + swDoc19.FullName);

                }

                config15 = (SwDMConfiguration15)config;


                if (config15.ShowChildComponentsInBOM2 == (int)swDmShowChildComponentsInBOMResult.swDmShowChildComponentsInBOM_TRUE)
                    config15.ShowChildComponentsInBOM2 = (int)swDmShowChildComponentsInBOMResult.swDmShowChildComponentsInBOM_FALSE;

                /* cerco configurazione costruttiva */
                sConfigurazioneCostr = sConfig;

                
                configCostr = default(SwDMConfiguration12);
                configCostr = (SwDM.SwDMConfiguration12)configMgr.GetConfigurationByName(sConfigurazioneCostr);

                sParentConf = configCostr.GetParentConfigurationName();

                while (sParentConf != null && sParentConf.Trim() != "")
                {

                    sConfigurazioneCostr = sParentConf;

                    configCostr = (SwDM.SwDMConfiguration12)configMgr.GetConfigurationByName(sConfigurazioneCostr);

                    sParentConf = configCostr.GetParentConfigurationName();

                }


                vCustPropNameArr = (string[])config.GetCustomPropertyNames();
                
                lFound = false;
                lFoundFaiAcquista = false;
                lFoundGuid = false;
                lFoundCategoria3_prefix = false;

                if ((vCustPropNameArr != null))
                {

                    for (int k = 0; k < vCustPropNameArr.Length; k++)
                    {


                        if (vCustPropNameArr[k].ToUpper() == "ICMREFBOMGUID")
                        {
                            lFound = true;
                        }

                        
                        if (vCustPropNameArr[k].ToUpper() == "FAIACQUISTA")
                        {
                            lFoundFaiAcquista = true;
                        }
                        

                        if (vCustPropNameArr[k].ToUpper() == "ICMBOMGUID")
                        {
                            lFoundGuid = true;
                        }

                        if (vCustPropNameArr[k].ToUpper() == "CATEGORIA3_PREFIX")
                        {
                            lFoundCategoria3_prefix = true;
                        }

                        if (lFound && lFoundGuid && lFoundFaiAcquista && lFoundCategoria3_prefix)
                            break;
                    }

                }

                if (sParteAssieme == "Parte")
                {

                    sFaiAcquista = "ACQUISTA";

                }
                else
                {

                    sFaiAcquista = "FAI";

                    if (lFoundCategoria3_prefix)
                    {

                        sCustPropStr = config.GetCustomProperty("CATEGORIA3_PREFIX", out nPropType);


                        if (sCustPropStr == null || sCustPropStr.Trim() == "")
                        {

                            //Nothing

                        }
                        else if (sCustPropStr.ToUpper() == "AS")   // Assieme saldato
                        {

                            sFaiAcquista = "ACQUISTA";


                        }

                    }

                }

                
                if (lFoundFaiAcquista)
                {

                    sCustPropStr = config.GetCustomProperty("FaiAcquista", out nPropType);


                    if (sCustPropStr == null || sCustPropStr.Trim() == "")
                    {

                        config.SetCustomProperty("FaiAcquista", sFaiAcquista);

                    }



                }
                else
                {

                    config.AddCustomProperty("FaiAcquista", SwDmCustomInfoType.swDmCustomInfoText, sFaiAcquista);

                }
                

                if (lFound)
                {

                    sCustPropStr = config.GetCustomProperty("ICMRefBOMGUID", out nPropType);


                    if (sCustPropStr == null || sCustPropStr.Trim() == "")
                    {


                        
                        config.SetCustomProperty("ICMRefBOMGUID", "THIS");

                        

                    }

                }
                else
                {
                    

                        config.AddCustomProperty("ICMRefBOMGUID", SwDmCustomInfoType.swDmCustomInfoText, "THIS");


                   
                }

                lChangedGUID = false;

                configurationGUID = "";


                if (lFoundGuid)
                {
                    string sCurrentGuid;
                    SwDmCustomInfoType parType;

                    sCurrentGuid = config.GetCustomProperty("ICMBOMGUID", out parType);

                    if (sCurrentGuid == null || sCurrentGuid.Trim() == "")
                    {
                        Guid newGuid;

                        newGuid = Guid.NewGuid();

                        config.SetCustomProperty("ICMBOMGUID", newGuid.ToString());

                        lChangedGUID = true;
                        configurationGUID = newGuid.ToString();

                    }
                    else
                    {

                        configurationGUID = sCurrentGuid;

                    }

                }
                else
                {
                    Guid newGuid;

                    newGuid = Guid.NewGuid();

                    config.AddCustomProperty("ICMBOMGUID", SwDmCustomInfoType.swDmCustomInfoText, newGuid.ToString());

                    lChangedGUID = true;

                    configurationGUID = newGuid.ToString();

                }

                /* salva Computed BOM per configurazione (non usare) */                

                /*if (true)
                {

                    IEdmFile7 aFile;
                    IEdmFolder5 ppoRetParentFolder;

                    string cTipoDistinta;

                    int plFocusNode = 0;

                    string sErrorMessage;

                    sErrorMessage = "";

                    aFile = (IEdmFile7)this.vault.GetFileFromPath(cFileName, out ppoRetParentFolder);

                    if (aFile != null)
                    {
                        IEdmEnumeratorVariable7 enumVar;

                        object[] ppoRetVars = null;
                        string[] ppoRetConfs = null;
                        EdmGetVarData poRetDat = new EdmGetVarData();
                        string sVersion;

                        enumVar = (IEdmEnumeratorVariable7)aFile.GetEnumeratorVariable();
                        enumVar.GetVersionVars(0, ppoRetParentFolder.ID, out ppoRetVars, out ppoRetConfs, ref poRetDat);


                        sVersion = poRetDat.mlLatestVersion.ToString();


                        //MessageBox.Show(cFileName + " --- " + sConf);
                        if (sParteAssieme == "Assieme")
                            cTipoDistinta = "DistintaAssiemePerArca";
                        else
                            cTipoDistinta = "DistintaPartePerArca";



                        bomView = aFile.GetComputedBOM(cTipoDistinta,  -1, sConfig, (int)EdmBomFlag.EdmBf_ShowSelected);

                        object[] ppoRows = null;
                        IEdmBomCell ppoRow = default(IEdmBomCell);
                        bomView.GetRows(out ppoRows);                        
                        int arrSize = ppoRows.Length;

                        //MessageBox.Show(arrSize.ToString());
                        string sBomName;

                        sBomName = (configurationGUID + "_" + sConfig + "_" + sVersion);

                        sBomName = sBomName.Replace("\\", "_");

                        bomView.Commit(sBomName, out sErrorMessage, out plFocusNode);

                        if (sErrorMessage != "")
                        {

                            TS.WriteLine(sErrorMessage, TraceEventType.Error);
                        
                        
                        }
                        
                    }


                }
                */



            }


            /*
            vCustPropNameArr = (string[])swDoc19.GetCustomPropertyNames();

            lFoundGuid = false;

            if ((vCustPropNameArr != null))
            {

                for (int k = 0; k < vCustPropNameArr.Length; k++)
                {


                    if (vCustPropNameArr[k].ToUpper() == "GUIDDOCUMENTO")
                    {
                        lFoundGuid = true;
                    }


                }

                if (lFoundGuid)
                {
                    string sCurrentGuid;
                    SwDmCustomInfoType parType;

                    sCurrentGuid = swDoc19.GetCustomProperty("GuidDocumento", out parType);

                    if (sCurrentGuid == null || sCurrentGuid.Trim() == "")
                    {
                        Guid newGuid;

                        newGuid = Guid.NewGuid();

                        swDoc19.SetCustomProperty("GuidDocumento", newGuid.ToString());

                    }

                }
                else
                {
                    Guid newGuid;

                    newGuid = Guid.NewGuid();

                    swDoc19.AddCustomProperty("GuidDocumento", SwDmCustomInfoType.swDmCustomInfoText, newGuid.ToString());

                }

            }

            */

            PopulateFile (swDoc19, cFileName, first);

            swDoc19.Save();
            swDoc19.CloseDoc();

            cacheFile.Add(cFileName);

        }

        public void PopulateFile(SwDM.SwDMDocument19 swDoc19, string cFileName, bool first)
        {

            string sName;
            string sPath;
            int iID;
            string[] vCfgNameArr = null;
            int i;
            string sConfig;
            string useConfig;


            Dictionary<Int32, String> compDict;
            compDict = new Dictionary<Int32, String>();



            SwDM.SwDMDocument19 swDocComp;
            SwDM.SwDMConfiguration12 config;


            SwDMConfigurationMgr2 configMgr = default(SwDMConfigurationMgr2);
            configMgr = (SwDMConfigurationMgr2)swDoc19.ConfigurationManager;

            SwDMConfigurationError results = 0;

            vCfgNameArr = (string[])configMgr.GetConfigurationNames2(out results);

            if (results != SwDMConfigurationError.SwDMConfigurationError_None)
            {
                throw new ApplicationException("ERROR: Errore in ottenimento lista configurazioni per file: " + swDoc19.FullName);

            }

            useConfig = null;

            for (i = 0; i < vCfgNameArr.Length; i++)
            {

                sConfig = vCfgNameArr[i];

                

                config = default(SwDMConfiguration12);
                config = (SwDM.SwDMConfiguration12)configMgr.GetConfigurationByName(sConfig);

                if (config == null)
                {

                    throw new ApplicationException("ERROR: Errore in ottenimento configurazione " + sConfig + "per file: " + swDoc19.FullName);

                }

                object comps = config.GetComponents();

                if (comps != null)
                {

                    Array arrComps = (Array)comps;


                    foreach (SwDM.SwDMComponent11 swComp in arrComps)
                    {

                        //if (swComp.IsVirtual)
                        //continue;

                        sPath = swComp.PathName;

                        sPath = this.GetChangedReferencePath(this.vault, sPath, swDoc19);

                        if (sPath == "")
                        {
                            MessageBox.Show("ERROR: Path non trovato per component " + sPath);
                            throw new ApplicationException("ERROR: Path non trovato per component " + sPath);
                        }
                        

                        NavigateFile(sPath, false);


                    }


                }

                

            }

        }


        public string GetChangedReferencePath(IEdmVault5 iVault, string sInitialPath, SwDM.SwDMDocument19 swDoc19)
        {

                string sNewPath;

                object objOriginalReferences;
                object objNewReferences;

                string[] originalReferences;
                string[] newReferences;

                swDoc19.GetChangedReferences(out objOriginalReferences, out objNewReferences);

                originalReferences = (string[])objOriginalReferences;
                newReferences = (string[])objNewReferences;

                sNewPath = sInitialPath;

                int i;

                int j;

                if (originalReferences != null)
                {

                    if (originalReferences.Length > 0)
                    {

                        j = 0;
                        i = originalReferences.Length - 1;

                        while (i >= j)
                        {

                            if (System.IO.Path.GetFileName(originalReferences[i]) == System.IO.Path.GetFileName(sNewPath))
                            {

                                sNewPath = newReferences[i];

                                j = i + 1;
                                i = originalReferences.Length - 1;

                                continue;

                            }

                            i--;
                        }


                    }

                }

                if ((!File.Exists(sNewPath)) && (!(iVault == null)))
                {

                    /* ricerca file per nome */
                    string cFileName = System.IO.Path.GetFileName(sNewPath);

                    IEdmSearch6 Search = (IEdmSearch6)iVault.CreateSearch();
                    if (Search != null)
                    {


                        Search.FindFiles = true;
                        Search.FindFolders = false;


                        Search.SetToken(EdmSearchToken.Edmstok_Name, cFileName);


                        IEdmSearchResult5 SearchResult = Search.GetFirstResult();
                        while ((SearchResult != null))
                        {

                            int id;
                            int parent_folder_id;

                            IEdmObject5 pdmObject;
                            IEdmFile5 pdmFile;

                            id = SearchResult.ID;
                            parent_folder_id = SearchResult.ParentFolderID;

                            pdmObject = default(IEdmObject5);

                            pdmObject = iVault.GetObject(EdmObjectType.EdmObject_File, id);

                            if (pdmObject != null)
                            {

                                pdmFile = (IEdmFile5)pdmObject;

                                sNewPath = pdmFile.GetLocalPath(parent_folder_id);


                            }

                            break;
                        }

                    }

                }


                if (!File.Exists(sNewPath))
                {

                    throw new ApplicationException("ERRORE: File " + sNewPath + " non trovato.");
                }



                return sNewPath;

        }


        public void OpenFile(string filename, out SwDM.SwDMDocument19 swDoc19, bool lReadonly, bool bTS)
        {

            string sDocFileName = null;
            SwDM.SwDmDocumentType nDocType = 0;
            SwDM.SwDmDocumentOpenError nRetVal = 0;

            swDoc19 = null;

            sDocFileName = filename;
            if (sDocFileName.ToLower().EndsWith("sldprt"))
            {
                nDocType = SwDM.SwDmDocumentType.swDmDocumentPart;
            }
            else if (sDocFileName.ToLower().EndsWith("sldasm"))
            {
                nDocType = SwDM.SwDmDocumentType.swDmDocumentAssembly;
            }
            else if (sDocFileName.ToLower().EndsWith("slddrw"))
            {
                nDocType = SwDM.SwDmDocumentType.swDmDocumentDrawing;
            }
            else
            {

                // Not a SOLIDWORKS file 
                nDocType = SwDM.SwDmDocumentType.swDmDocumentUnknown;


                return;
            }

            if (bTS)
                WriteLog("Apertura file con Document Manager: " + sDocFileName);
            
            swDoc19 = (SwDM.SwDMDocument19)swDocMgr.GetDocument(sDocFileName, nDocType, lReadonly, out nRetVal);
            
            

            if (swDoc19 == null)
            {
                MessageBox.Show("Errore apertura file " + sDocFileName + "Codice Errore: " + nRetVal.ToString());
            }

        }

    }
}
