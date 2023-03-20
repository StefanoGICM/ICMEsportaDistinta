using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Forms;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using EPDM.Interop.epdm;
using ICM.ConsoleControlWPF;

namespace ICM.SWPDM.EsportaDistintaAddin
{
    /// <summary>
    /// Interaction logic for UserControl1.xaml
    /// </summary>
    public partial class EsportaDistintaForm : Window
    {


        EsportaDistinta EspDistinta = new EsportaDistinta(1);


        string sFileName;
        int iVersione;
        int iDocument;

        IEdmVault5 vault;
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


        private async void Button_Click(object sender, RoutedEventArgs e)
        {
            string sFileName = this.sFileName;
            string sConfigurazioni = ConfigurazioniTextBox.Text;

            bool? bTopOnly = this.checkFirstOnly.IsChecked;
            string sDitta = this.dittaTextBox.ToString();

            if (bTopOnly == null)
                bTopOnly = false;

            string sEsplodiPar1;
            string sEsplodiPar2;
            bool bSet1;
            bool bSet2;
            int iSelectedRootVersion;



            if ((sConfigurazioni == null) || (sConfigurazioni.Trim() == ""))
            {

                System.Windows.Forms.MessageBox.Show("Nessuna configurazione impostata");
                return;


            }

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

                        sEsplodiPar1 = "";
                        sEsplodiPar2 = "";
                        bSet1 = false;
                        bSet2 = false;


                        iSelectedRootVersion = 0;

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

                        progBarAnalisi.Foreground = Brushes.Green;

                        Guid newSessionId = Guid.NewGuid();

                        PreEsportaDistinta preEsportaDistinta = new PreEsportaDistinta();

                        long id;

                        id = 0;

                        /* aggiunge record nella tabella di esportazione */
                        preEsportaDistinta.insertDistinta(this.vault
                                                          , this.iDocument
                                                          , this.sFileName
                                                          , this.iVersione
                                                          , sConfigurazioni
                                                          , bTopOnly
                                                          , sEsplodiPar1
                                                          , sEsplodiPar1
                                                          , sDitta
                                                          , 0
                                                          , newSessionId
                                                          , out id
                                                          );




                        //await Task.Run(() => EspDistinta.IniziaEsportazione(iDocument, sFileName, iVersione, sConfigurazioni, vault, false, sEsplodiPar1, sEsplodiPar2));

                        //EspDistinta.WriteLog("-----------------------------------------------------------------------", TraceEventType.Information);
                        //EspDistinta.WriteLog("Esportazione terminata con successso", TraceEventType.Information);
                        //EspDistinta.WriteLog("-----------------------------------------------------------------------", TraceEventType.Information);

                    }
                    catch (Exception ex)
                    {

                        //System.Windows.Forms.MessageBox.Show(ex.Message);

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
    
        

        private async void Button_Click_1(object sender, RoutedEventArgs e)
        {

            string sFileName = this.sFileName;
            string sConfigurazioni = ConfigurazioniTextBox.Text;

            

            DialogResult dialogResult = System.Windows.Forms.MessageBox.Show("Confermi aggiornamento distinta pregressa ?", "Domanda", MessageBoxButtons.YesNo);
            if (dialogResult == System.Windows.Forms.DialogResult.Yes)
            {
                if ((sConfigurazioni == null) || (sConfigurazioni.Trim() == ""))
                {

                    System.Windows.Forms.MessageBox.Show("Nessuna configurazione impostata");
                    return;


                }

                if (sFileName != null)
                    try
                    {

                        progBarAnalisi.Foreground = Brushes.Green;


                        await Task.Run(() => EspDistinta.IniziaAggiornamento(sFileName, sConfigurazioni, vault));

                        EspDistinta.TS.WriteLine("-----------------------------------------------------------------------", TraceEventType.Information);
                        EspDistinta.TS.WriteLine("Aggiornamento terminato con successso", TraceEventType.Information);
                        EspDistinta.TS.WriteLine("-----------------------------------------------------------------------", TraceEventType.Information);

                    }
                    catch (Exception ex)
                    {
                        System.Windows.Forms.MessageBox.Show(ex.Message);
                        

                        EspDistinta.TS.WriteLine("-----------------------------------------------------------------------", TraceEventType.Error);
                        EspDistinta.TS.WriteLine("Aggiornamento terminato per errori", TraceEventType.Error);
                        EspDistinta.TS.WriteLine("-----------------------------------------------------------------------", TraceEventType.Error);

                        progBarAnalisi.Foreground = Brushes.Red;


                    }
                    finally
                    {
                        progBarAnalisi.Value = progBarAnalisi.Maximum;
                        //progBarClonazione.Value = progBarClonazione.Maximum;
                    }

                else
                {
                    //btnIniziaClonazione.IsEnabled = false;
                }
            }
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
    }
}
