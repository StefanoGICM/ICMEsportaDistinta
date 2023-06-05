using EPDM.Interop.epdm;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Net.NetworkInformation;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ICM.SWPDM.EsportaDistintaAddin
{
    public partial class SetupPage : UserControl

    {



        private IEdmVault7 mVault;

        private IEdmTaskProperties mTaskProps;

        private IEdmTaskInstance mTaskInst;

        // Constructor called from task setup

        public SetupPage(IEdmVault7 Vault, IEdmTaskProperties Props)

        {

            try

            {

                InitializeComponent();

                mVault = Vault;

                mTaskProps = Props;

                mTaskInst = null;



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

        // Constructor called from task details

        public SetupPage(IEdmVault7 Vault, IEdmTaskInstance Props)

        {

            try

            {

                InitializeComponent();

                mVault = Vault;

                mTaskProps = null;

                mTaskInst = Props;



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




        public void LoadData(EdmCmd poCmd)

        {

            try

            {


                string sTopLevel;
                string sCancella;


                int iTopLevel;
                int iCancella;

                if ((mTaskProps != null))
                {


                    assiemeTextBox.Text = this.mTaskProps.GetValEx("AssiemeVar");
                    confTextBox.Text = this.mTaskProps.GetValEx("confVar");
                    padreListBox.Text = this.mTaskProps.GetValEx("padreVar");
                    figliListBox.Text = this.mTaskProps.GetValEx("figliVar");
                    sTopLevel = this.mTaskProps.GetValEx("topLevelVar");
                    sCancella = this.mTaskProps.GetValEx("cancellaVar");
                    outputListBox.Text = this.mTaskProps.GetValEx("outputVar");
                    connARCATextBox.Text = this.mTaskProps.GetValEx("connARCAVar");
                    dirFileXMLTextBox.Text = this.mTaskProps.GetValEx("dirFileXMLVar");                    
                    connICMSWDataTextBox.Text = this.mTaskProps.GetValEx("connICMSWDataVar");
                    noteTextBox.Text = this.mTaskProps.GetValEx("noteVar");
                    selezioneVersionePadreTextBox.Text = this.mTaskProps.GetValEx("selezioneVersionePadreVar");


                    if (sTopLevel == "1")
                        topLevelCheckBox.Checked = true;
                    else
                        topLevelCheckBox.Checked = false;

                    if (sCancella == "1")
                        cancellaCheckBox.Checked = true;
                    else
                        cancellaCheckBox.Checked = false;


                }
                else if ((mTaskInst != null))
                {
                    assiemeTextBox.Text = this.mTaskInst.GetValEx("AssiemeVar");
                    confTextBox.Text = this.mTaskInst.GetValEx("confVar");
                    padreListBox.Text = this.mTaskInst.GetValEx("padreVar");
                    figliListBox.Text = this.mTaskInst.GetValEx("figliVar");
                    sTopLevel = this.mTaskInst.GetValEx("topLevelVar");
                    sCancella = this.mTaskInst.GetValEx("cancellaVar");
                    outputListBox.Text = this.mTaskInst.GetValEx("outputVar");
                    connARCATextBox.Text = this.mTaskInst.GetValEx("connARCAVar");
                    dirFileXMLTextBox.Text = this.mTaskInst.GetValEx("dirFileXMLVar");
                    connICMSWDataTextBox.Text = this.mTaskInst.GetValEx("connICMSWDataVar");                    
                    noteTextBox.Text = this.mTaskInst.GetValEx("noteVar");
                    selezioneVersionePadreTextBox.Text = this.mTaskInst.GetValEx("selezioneVersionePadreVar");


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



        public void StoreData()

        {

            int iTopLevel = 0;
            int iCancella = 0;

            try

            {

                if (topLevelCheckBox.Checked)
                {

                    iTopLevel = 1;

                }
                else
                {

                    iTopLevel = 0;

                }

                if (cancellaCheckBox.Checked)
                {

                    iCancella = 1;

                }
                else
                {

                    iCancella = 0;

                }



                this.mTaskProps.SetValEx("AssiemeVar", assiemeTextBox.Text);
                this.mTaskProps.SetValEx("confVar", confTextBox.Text);
                this.mTaskProps.SetValEx("padreVar", padreListBox.Text);
                this.mTaskProps.SetValEx("figliVar", figliListBox.Text);
                this.mTaskProps.SetValEx("topLevelVar", iTopLevel.ToString());
                this.mTaskProps.SetValEx("cancellaVar", iCancella.ToString());
                this.mTaskProps.SetValEx("outputVar", outputListBox.Text);
                this.mTaskProps.SetValEx("connARCAVar", connARCATextBox.Text);
                this.mTaskProps.SetValEx("dirFileXMLVar", dirFileXMLTextBox.Text);                
                this.mTaskProps.SetValEx("connICMSWDataVar", connICMSWDataTextBox.Text);
                this.mTaskProps.SetValEx("noteVar", noteTextBox.Text);
                this.mTaskProps.SetValEx("selezioneVersionePadreVar", selezioneVersionePadreTextBox.Text);

                





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

        public void DisableControls()

        {

            try

            {

                confTextBox.Enabled = false;
                padreListBox.Enabled = false;
                figliListBox.Enabled = false;
                topLevelCheckBox.Enabled = false;
                cancellaCheckBox .Enabled = false;
                outputListBox.Enabled = false;
                connARCATextBox.Enabled = false;
                dirFileXMLTextBox.Enabled = false;
                connICMSWDataTextBox.Enabled = false;
                connICMSWDataTextBox.Enabled = false;
                noteTextBox.Enabled = false;

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

        private void SetupPage_Load(object sender, EventArgs e)
        {

        }

        private void StatesListBox_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void listBox1_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void assiemeTextBox_TextChanged(object sender, EventArgs e)
        {

        }
    }
}
