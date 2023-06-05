using EPDM.Interop.epdm;
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


           

        }


        /*public async void OpenSocket()
        {            
            
            IPHostEntry host = Dns.GetHostEntry("localhost");
            IPAddress ipAddress = host.AddressList[0];

            IPAddress ipAddress2 = default(IPAddress);

            IPAddress[] addresses = Dns.GetHostAddresses("");

            string sIpAddress = "";

            foreach (IPAddress address in addresses)
            {
                if (address.ToString().StartsWith("192."))
                {

                    ipAddress2 = address;
                    sIpAddress = address.ToString();

                    break;

                }

            }
            

            this.ipEndPoint = CreateIPEndPoint(sIpAddress + ":11201" );


            //this.listener = new Socket(
            //    this.ipEndPoint.AddressFamily,
            //    SocketType.Stream,
            //    ProtocolType.Tcp);

            listener = new TcpListener(ipEndPoint);

            listener.Start();

            WaitForClients();

            //this.listener.Bind(this.ipEndPoint);
            //this.listener.Listen(100);

            //listener.AcceptAsync();
            // Connect to the remote endpoint.

            try
            {
                var tcpClient = await listener.AcceptTcpClientAsync();
                HandleConnectionAsync(tcpClient);
                
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
            

        }

        */
        /*
        private async void HandleConnectionAsync(TcpClient tcpClient)
        {
            //Write code here to process the incoming client connections
        }
        */
        /*
        private static void WaitForClients()
        {
            listener.BeginAcceptTcpClient(new System.AsyncCallback(OnClientConnected), null);
        }
        */
        /*
        private static void OnClientConnected(IAsyncResult asyncResult)
        {
            try
            {
                TcpClient clientSocket = listener.EndAcceptTcpClient(asyncResult);                
                HandleClientRequest(clientSocket);
            }
            catch
            {
                throw;
            }

            WaitForClients();
        }

        */
        /*
        private static async void HandleClientRequest(TcpClient clientSocket)
        {
            //Write your code here to process the data
            //System.Windows.Forms.MessageBox.Show(clientSocket.ReceiveBufferSize.ToString());            

            new Thread(() =>
            {
                Thread.CurrentThread.IsBackground = true;

                int numberChars;
                NetworkStream netStream;
                netStream = clientSocket.GetStream();
                var reader = new StreamReader(netStream);
                //char[] receiveBuffer = new char[4096];
                string toSend;
                string fine;
                bool bBreak = false;

                while (true)
                {

                    if (netStream.DataAvailable)
                    {

                        //var datarec = netStream.Read(receiveBuffer, 0, 4096);

                        char[] receiveBuffer = new char[4096];

                        numberChars = reader.Read(receiveBuffer, 0, 4096);

                        toSend = new string(receiveBuffer);

                        fine = ((char)1).ToString() + ((char)1).ToString() + ((char)1).ToString() + ((char)1).ToString();

                        if (toSend.Contains(fine))
                        {

                            toSend = toSend.Replace(fine, "    ");

                            bBreak = true;

                        
                        }

                        toSend = toSend.Substring(0, numberChars);

                        

                        TSStatic.WriteLine(toSend);

                        if (bBreak)
                            break;

                    }

                    
                    


                }

                listener.Stop();
                netStream.Close();
                netStream.Dispose();

            }).Start();

           
        }
        */
        /*private static void Receive(Socket client)
        {
            try
            {
                // Create the state object.
                StateObject state = new StateObject();
                state.workSocket = client;

                // Begin receiving the data from the remote device.
                client.BeginReceive(state.buffer, 0, StateObject.BufferSize, 0,
                    new AsyncCallback(ReceiveCallback), state);
            }
            catch (Exception e)
            {
                throw e;
            }
        }*/

        /*private static void ReceiveCallback(IAsyncResult ar)
        {
            try
            {
                // Retrieve the state object and the client socket 
                // from the asynchronous state object.
                StateObject state = (StateObject)ar.AsyncState;
                Socket client = state.workSocket;

                string stopReceiving;
                stopReceiving = ((char)1).ToString() + ((char)1).ToString() + ((char)1).ToString() + ((char)1).ToString();

                string response;
                

                bStop = false;

                // Read data from the remote device.
                int bytesRead = client.EndReceive(ar);

                if (bytesRead > 0)
                {
                    // There might be more data, so store the data received so far.
                    response = Encoding.ASCII.GetString(state.buffer, 0, bytesRead);
                    
                    TSStatic.WriteLine(response);

                    if (response.Contains("Elaborazione interrotta per errori"))
                        bElabOK = false;

                    if (response.Contains(stopReceiving))
                    {

                        response = response.Replace(stopReceiving, "");
                        bStop = true;

                    }

                }


            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }
        }*/


        /*private static void ConnectCallback(IAsyncResult ar)
        {
            try
            {
                // Retrieve the socket from the state object.
                Socket client = (Socket)ar.AsyncState;

                // Complete the connection.
                client.EndConnect(ar);


                // Signal that the connection has been made.
                connectDone.Set();
            }

            catch (Exception e)
            {
                throw e;
            }
        }*/

        /*public class StateObject
        {
            // Client socket.
            public Socket workSocket = null;
            // Size of receive buffer.
            public const int BufferSize = 256;
            // Receive buffer.
            public byte[] buffer = new byte[BufferSize];
            // Received data string.
            public StringBuilder sb = new StringBuilder();
        }*/



        /*public  async Task ReadFromSocketAsync()
        {
            //Stuff Happens on the original UI thread

            //await Task.Run(() => //This code runs on a new thread, control is returned to the caller on the UI thread.

              //  ReadFromSocket());


            await ReadFromSocket();
            //Stuff Happens on the original UI thread after the loop exits.
            //System.Windows.Forms.MessageBox.Show("pippo");
        }
        */








        /*public void  ProcessReceive(SocketAsyncEventArgs readEventArgs)
        {

            string stopReceiving;
            stopReceiving = ((char)1).ToString() + ((char)1).ToString() + ((char)1).ToString() + ((char)1).ToString();

            bool bStop;

            bStop = false;

            

                
            //var received = this.handler.Receive(buffer);

            var response = Encoding.UTF8.GetString(readEventArgs.Buffer, 0, readEventArgs.Buffer.Length);

            if (response != null && response.Trim() != "")
            {


                if (response.Contains("Elaborazione interrotta per errori"))
                    this.bElabOK = false;

                if (response.Contains(stopReceiving))
                {

                    response = response.Replace(stopReceiving, "");
                    bStop = true;

                }


                this.EspDistinta.TS.WriteLine(response);

                System.Windows.Forms.Application.DoEvents();


                if (bStop)
                {
                    this.listener.Close();

                    if (this.bElabOK)
                        this.EspDistinta.DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;
                    else
                    {

                        progBarAnalisi.Foreground = Brushes.Red;
                        this.EspDistinta.DocumentsAnalysisStatus = enumDocumentAnalysisStatus.Completed;


                    }


                }

            }

        

        }
        */

        /*public void CloseSocket()                
        {

            //this.listener.Shutdown(SocketShutdown.Both);
            //this.listener.Close();
        }
        */

        // Handles IPv4 and IPv6 notation.
        /*public static IPEndPoint CreateIPEndPoint(string endPoint)
        {
            string[] ep = endPoint.Split(':');
            if (ep.Length < 2) throw new FormatException("Invalid endpoint format");
            IPAddress ip;
            if (ep.Length > 2)
            {
                if (!IPAddress.TryParse(string.Join(":", ep, 0, ep.Length - 1), out ip))
                {
                    throw new FormatException("Invalid ip-adress");
                }
            }
            else
            {
                if (!IPAddress.TryParse(ep[0], out ip))
                {
                    throw new FormatException("Invalid ip-adress");
                }
            }
            int port;
            if (!int.TryParse(ep[ep.Length - 1], NumberStyles.None, NumberFormatInfo.CurrentInfo, out port))
            {
                throw new FormatException("Invalid port");
            }
            return new IPEndPoint(ip, port);

        }
        */

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

            Debugger.Launch();

            string sFileName = this.sFileName;
            string sConfigurazioni = ConfigurazioniTextBox.Text;

            bool? bTopOnly = this.checkFirstOnly.IsChecked;
            string sConnARCA;
            string sConnFrontiera;

            sConnARCA = this.connARCA.Text;
            sConnFrontiera = this.connFrontiera.Text;

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


                        EspDistinta.TS.WriteLine("Record inserito nella queue di esportazione");

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
    
        

        private async void Button_Click_1(object sender, RoutedEventArgs e)
        {

            string sFileName = this.sFileName;
            string sConfigurazioni = ConfigurazioniTextBox.Text;

            

            DialogResult dialogResult = System.Windows.Forms.MessageBox.Show("Confermi aggiornamento distinta pregressa ?", "Domanda", MessageBoxButtons.YesNo);
            if (dialogResult == System.Windows.Forms.DialogResult.Yes)
            {
                /*if ((sConfigurazioni == null) || (sConfigurazioni.Trim() == ""))
                {

                    System.Windows.Forms.MessageBox.Show("Nessuna configurazione impostata");
                    return;


                }*/

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

        private void FileName_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
        {

        }
    }
}
