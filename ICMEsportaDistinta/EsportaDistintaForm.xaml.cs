﻿using EPDM.Interop.epdm;
using ICM.ConsoleControlWPF;
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Media;



namespace ICM.SWPDM.EsportaDistintaAddin
{
    /// <summary>
    /// Interaction logic for UserControl1.xaml
    /// </summary>
    public partial class EsportaDistintaForm : Window
    {


        EsportaDistinta EspDistinta = new EsportaDistinta(1);

        byte[] bytesReceived = new byte[1_024];
        
        string sFileName;
        int iVersione;
        int iDocument;

        string returnedMessage;

        static bool bElabOK;
        static bool bStop;

        static TraceSource TSStatic;

        IEdmVault5 vault;



        // inizializza socket client

        static TcpListener listener;
        IPEndPoint ipEndPoint;

        Socket handler;

        private static ManualResetEvent connectDone =
        new ManualResetEvent(false);
        private static ManualResetEvent sendDone =
            new ManualResetEvent(false);
        private static ManualResetEvent receiveDone =
            new ManualResetEvent(false);


        //public EsportaDistintaForm()
        //{
        //InitializeComponent();
        //}

        public EsportaDistintaForm(int iDocument, string sFileName,int iVersione, IEdmVault5 vault)            
        {
            this.iDocument = iDocument;
            this.sFileName = sFileName;
            this.iVersione = iVersione;
            this.vault = vault;

            EspDistinta.PropertyChanged += EsportaDistinta_PropertyChanged;

            this.WindowStartupLocation = WindowStartupLocation.CenterScreen;

            InitializeComponent();

            DistintaTextBox.Text = "Distinta: " + sFileName;
            DistintaTextBox.IsReadOnly = true;

            //EspDistinta.PropertyChanged += EsportaDistinta_PropertyChanged;
            EspDistinta.TS.Listeners.Add(new ThisAssemblyTraceListener(consoleControl));

            SourceSwitch sourceSwitch = new SourceSwitch(Assembly.GetExecutingAssembly().FullName);
            sourceSwitch.Level = SourceLevels.Verbose;
            EspDistinta.TS.Switch = sourceSwitch;

            EspDistinta.TS.WriteLine("Test Console");

            TSStatic = EspDistinta.TS;

            //DbARCACombo Inizializzazione

            DbARCACombo.ItemsSource = null;
            DbARCACombo.Items.Clear();//Nie wolno używać gdy jest podpięty ItemsSource, chyba że jest null'em

            System.Collections.Generic.Dictionary<string, string> DbARCAComboSource = new System.Collections.Generic.Dictionary<string, string>();

            DbARCAComboSource.Add("ADB_FREDDO", "Data Source='erp';Initial Catalog = ADB_FREDDO; User ID = sa; Password = 'Logitech0'; MultipleActiveResultSets=True");
            DbARCAComboSource.Add("ADB_ICM", "Data Source='erp';Initial Catalog = ADB_ICM; User ID = sa; Password = 'Logitech0'; MultipleActiveResultSets=True");

            DbARCACombo.ItemsSource = DbARCAComboSource;//Przypisanie kolekcji do ComboBox'a
            DbARCACombo.DisplayMemberPath = "Key";//Wybór kolumny do wyświetlenia

            DbARCACombo.Items.Refresh();

            DbARCACombo.SelectedIndex = 0;

            //DbFrontieraCombo Inizializzazione

            DbFrontieraCombo.ItemsSource = null;
            DbFrontieraCombo.Items.Clear();//Nie wolno używać gdy jest podpięty ItemsSource, chyba że jest null'em

            System.Collections.Generic.Dictionary<string, string> DbFrontieraComboSource = new System.Collections.Generic.Dictionary<string, string>();

            DbFrontieraComboSource.Add("ICMSWDataTest", "Data Source='PDMTest';Initial Catalog = ICMSWDataTest; User ID = sa; Password = 'P@ssw0rd'; MultipleActiveResultSets=True");
            DbFrontieraComboSource.Add("ICMSWData", "Data Source='PDMTest';Initial Catalog = ICMSWData; User ID = sa; Password = 'P@ssw0rd'; MultipleActiveResultSets=True");
            

            DbFrontieraCombo.ItemsSource = DbFrontieraComboSource;//Przypisanie kolekcji do ComboBox'a
            DbFrontieraCombo.DisplayMemberPath = "Key";//Wybór kolumny do wyświetlenia

            DbFrontieraCombo.Items.Refresh();

            DbFrontieraCombo.SelectedIndex = 0;





        }



        private void EsportaDistinta_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            switch (e.PropertyName)
            {
                case "DocumentsAnalyzed":
                    this.Dispatcher.Invoke(() =>
                    {

                        if (EspDistinta.DocumentsAnalysisStatus == enumDocumentAnalysisStatus.Started)
                        {
                            progBarAnalisi.IsIndeterminate = true;
                        }
                        else if (EspDistinta.DocumentsAnalysisStatus == enumDocumentAnalysisStatus.Completed)
                        {
                            progBarAnalisi.IsIndeterminate = false;
                            progBarAnalisi.Value = progBarAnalisi.Maximum;
                        }
                    });
                    break;
            }
        }
        public enum enumDocumentAnalysisStatus
        {
            Started,
            Completed
        }


        private void Button_Click(object sender, RoutedEventArgs e)
        {
            

            string sFileName = this.sFileName;
            string sConfigurazioni = ConfigurazioniTextBox.Text;

            bool? bTopOnly = this.checkFirstOnly.IsChecked;
            string sConnARCA;
            string sConnFrontiera;



            sConnARCA = ((System.Collections.Generic.KeyValuePair<string, string>)DbARCACombo.SelectedItem).Value.ToString();
            sConnFrontiera = ((System.Collections.Generic.KeyValuePair<string, string>)DbFrontieraCombo.SelectedItem).Value.ToString();

            System.Windows.Forms.MessageBox.Show(sConnARCA);
            System.Windows.Forms.MessageBox.Show(sConnFrontiera);

            return;

            sConnARCA = sConnARCA.Replace(@"\\", @"\");
            sConnFrontiera = sConnFrontiera.Replace(@"\\", @"\");

            if (bTopOnly == null)
                bTopOnly = false;

            string sEsplodiPar1;
            string sEsplodiPar2;
            bool bSet1;
            bool bSet2;
            int iSelectedRootVersion;

            int iDeleteFrontiera;

            int iOutput = 0;
            string cOutputDir;
            string cNote;

            /*if ((sConfigurazioni == null) || (sConfigurazioni.Trim() == ""))
            {

                System.Windows.Forms.MessageBox.Show("Nessuna configurazione impostata");
                return;


            }*/

            iSelectedRootVersion = 0;

            if ((bool)RB2.IsChecked)
            {

                bool bSuccess;

                bSuccess = int.TryParse(VerPadre.Text, out iSelectedRootVersion);
                if (!bSuccess)
                {

                    System.Windows.Forms.MessageBox.Show("Versione Padre non valida");
                    return;

                }

            }

            DialogResult dialogResult = System.Windows.Forms.MessageBox.Show("Confermi esportazione distinta ?", "Domanda", MessageBoxButtons.YesNo);
            if (dialogResult == System.Windows.Forms.DialogResult.Yes)
            {

                if (sFileName != null)
                {
                    try
                    {

                        progBarAnalisi.Foreground = Brushes.Green;
                        this.EspDistinta.DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Started;


                        sEsplodiPar1 = "";
                        sEsplodiPar2 = "";
                        bSet1 = false;
                        bSet2 = false;

                        if ((bool)RB7.IsChecked)
                            iOutput = 1;
                        else if ((bool)RB8.IsChecked)
                            iOutput = 2;
                        else
                            iOutput = 3;

                        //if ((iOutput == 1) && (sDitta.ToUpper() != "ICM") && (sDitta.ToUpper() != "FREDDO"))
                        //{

                            //System.Windows.Forms.MessageBox.Show("Ditta deve essere ICM o FREDDO");
                            //return;
                        
                        //}

                        if ((iOutput == 1) && (sConnARCA.ToUpper().Contains("ICM")))
                        {

                            string sMessage = "Attenzione: è stata scelta la ditta ICM. Sei sicuro di voler procedere ?";
                            DialogResult dialogResult2 = System.Windows.Forms.MessageBox.Show(sMessage, "Domanda", MessageBoxButtons.YesNo);

                            if (dialogResult != System.Windows.Forms.DialogResult.Yes)
                                return;

                        }
                        


                        cOutputDir = this.FileName.Text;

                        if (iOutput == 2)
                        {

                            if (cOutputDir == null || cOutputDir.Trim() == "")
                            {
                                System.Windows.Forms.MessageBox.Show("Indicare la directory di esportazione del file XML");
                                return;
                            }

                            if (!(Directory.Exists(cOutputDir)))
                            {

                                System.Windows.Forms.MessageBox.Show("La Directory " + cOutputDir + " non esiste");
                                return;

                            }

                            // tolgo l'eventuale backslash finale

                            if (cOutputDir.Substring(cOutputDir.Length - 1, 1) == @"\")
                                cOutputDir = cOutputDir.Substring(0, cOutputDir.Length - 1);

                        }


                        if ((bool)RB1.IsChecked)
                        {
                            sEsplodiPar1 = "UV";
                            bSet1 = true;

                        }

                        if ((bool)RB3.IsChecked)
                        {
                            sEsplodiPar1 = "UR";
                            bSet1 = true;
                        }

                        if ((bool)RB2.IsChecked)
                        {
                            sEsplodiPar1 = "SV";
                            bSet1 = true;

                        }

                        if ((bool)RB4.IsChecked)
                        {
                            sEsplodiPar1 += (char)1 + "UV";
                            bSet2 = true;

                        }

                        if ((bool)RB5.IsChecked)
                        {
                            sEsplodiPar1 += (char)1 + "UR";
                            bSet2 = true;

                        }

                        if ((bool)RB6.IsChecked)
                        {
                            sEsplodiPar1 += (char)1 + "CC";
                            bSet2 = true;
                        }

                        sEsplodiPar2 = iSelectedRootVersion.ToString();


                        if (!(bSet1 && bSet2))
                        {

                            throw new ApplicationException("Parametri non corretti");

                        }


                        Guid newSessionId = Guid.NewGuid();

                        PreEsportaDistinta preEsportaDistinta = new PreEsportaDistinta(this.EspDistinta);

                        long id;

                        id = 0;

                        if (deleteFrontiera.IsChecked == true)
                            iDeleteFrontiera = 1;
                        else
                            iDeleteFrontiera = 0;

                        cNote = NoteTB.Text;

                        /* aggiunge record nella tabella di esportazione */
                        preEsportaDistinta.insertDistinta(this.vault
                                                          , this.iDocument
                                                          , this.sFileName
                                                          , iSelectedRootVersion
                                                          , sConfigurazioni
                                                          , bTopOnly
                                                          , sEsplodiPar1
                                                          , sEsplodiPar2
                                                          , sConnARCA
                                                          , sConnFrontiera
                                                          , 0
                                                          , newSessionId
                                                          , out id
                                                          , "Form"
                                                          , 0
                                                          , iOutput
                                                          , cOutputDir
                                                          , iDeleteFrontiera
                                                          , cNote);


                        EspDistinta.TS.WriteLine("Operazione terminata");

                        bElabOK = true;

                        this.EspDistinta.DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;

                        //OpenSocket();


                        //var t = new Thread(ReadFromSocket);
                        //t.Name = "My Socket Thread";
                        //t.Priority = ThreadPriority.AboveNormal;
                        //t.Start("Thread");


                        //System.Windows.Forms.MessageBox.Show("pluto");

                        //CloseSocket();



                        //System.Windows.Forms.MessageBox.Show("Record inserito nella queue di esportazione");
                        //await Task.Run(() => EspDistinta.IniziaEsportazione(iDocument, sFileName, iVersione, sConfigurazioni, vault, false, sEsplodiPar1, sEsplodiPar2));

                        //EspDistinta.WriteLog("-----------------------------------------------------------------------", TraceEventType.Information);
                        //EspDistinta.WriteLog("Esportazione terminata con successso", TraceEventType.Information);
                        //EspDistinta.WriteLog("-----------------------------------------------------------------------", TraceEventType.Information);

                    }
                    catch (Exception ex)
                    {

                        progBarAnalisi.Foreground = Brushes.Red;
                        this.EspDistinta.DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;


                        EspDistinta.TS.WriteLine(ex.Message);
                        EspDistinta.TS.WriteLine("Elaborazione non riuscita");


                        //System.Windows.Forms.MessageBox.Show(ex.Message);
                        //System.Windows.Forms.MessageBox.Show("Elaborazione non riuscita");


                        //EspDistinta.WriteLog(ex.Message, TraceEventType.Error);

                        //EspDistinta.WriteLog("-----------------------------------------------------------------------", TraceEventType.Error);
                        //EspDistinta.WriteLog("Esportazione interrotta per errori", TraceEventType.Error);
                        //EspDistinta.WriteLog("-----------------------------------------------------------------------", TraceEventType.Error);

                        //progBarAnalisi.Foreground = Brushes.Red;


                    }
                    finally
                    {
                        progBarAnalisi.Value = progBarAnalisi.Maximum;
                        //progBarClonazione.Value = progBarClonazione.Maximum;
                    }

                }
                else
                {

                    System.Windows.Forms.MessageBox.Show("Nessun file selezionato");

                }

            }

        }

        private void ProgressBar_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {

        }
                   

        private void RadioButton_Checked(object sender, RoutedEventArgs e)
        {

        }

        private void RB2_Click(object sender, RoutedEventArgs e)
        {
            LabelVerPadre.Visibility = Visibility.Visible;
            VerPadre.Visibility = Visibility.Visible;
        }

        private void RB1_Click(object sender, RoutedEventArgs e)
        {
            LabelVerPadre.Visibility = Visibility.Hidden;
            VerPadre.Visibility = Visibility.Hidden;

        }

        private void RB3_Click(object sender, RoutedEventArgs e)
        {

            LabelVerPadre.Visibility = Visibility.Hidden;
            VerPadre.Visibility = Visibility.Hidden;

        }

        private void CheckBox_Checked(object sender, RoutedEventArgs e)
        {

        }

        private void FileName_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
        {

        }

        private void ComboBox_SelectionChanged(object sender, System.Windows.Controls.SelectionChangedEventArgs e)
        {

        }
    }
}
