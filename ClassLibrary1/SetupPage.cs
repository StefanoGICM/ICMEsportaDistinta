using EPDM.Interop.epdm;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
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

                //Add the names of the available workflows

                //to WorkflowsComboBox

                WorkflowsComboBox.Items.Clear();

                IEdmWorkflowMgr6 WorkflowMgr = default(IEdmWorkflowMgr6);

                WorkflowMgr = (IEdmWorkflowMgr6)mVault.CreateUtility(EdmUtility.EdmUtil_WorkflowMgr);

                IEdmPos5 WorkflowPos = WorkflowMgr.GetFirstWorkflowPosition();

                while (!WorkflowPos.IsNull)

                {

                    IEdmWorkflow6 Workflow = default(IEdmWorkflow6);

                    Workflow = WorkflowMgr.GetNextWorkflow(WorkflowPos);

                    WorkflowsComboBox.Items.Add(Workflow.Name);

                }



                string SelectedWorkflow = "";

                string NoDays = "";

                if ((mTaskProps != null))

                {

                    //Retrieve the name of the workflow that was

                    //selected by the user

                    SelectedWorkflow = (string)mTaskProps.GetValEx("SelectedWorkflowVar");

                    //Retrieve the number of days in a state

                    //before sending a message

                    NoDays = (string)mTaskProps.GetValEx("NoDaysVar");

                }

                else if ((mTaskInst != null))

                {

                    //Retrieve the name of the workflow that

                    //was selected by the user

                    SelectedWorkflow = (string)mTaskInst.GetValEx("SelectedWorkflowVar");

                    //Retrieve the number of days in a state

                    //before sending a message

                    NoDays = (string)mTaskInst.GetValEx("NoDaysVar");

                }



                //Select the workflow to display in

                //WorkflowsComboBox; setting this also

                //causes SetupPage::WorkflowsComboBox_SelectedIndexChanged

                //to be called to fill StatesListBox 

                //with the available states for this workflow

                if (string.IsNullOrEmpty(SelectedWorkflow))

                {

                    WorkflowsComboBox.SelectedIndex = 0;

                }

                else

                {

                    WorkflowsComboBox.Text = SelectedWorkflow;

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

            try

            {

                //Add the selected states to StatesList

                string StatesList = "";

                foreach (int SelectedStateIndex in StatesListBox.SelectedIndices)

                {

                    StatesList += StatesListBox.Items[SelectedStateIndex] + "";

                }

                //Save the states selected by the user

                mTaskProps.SetValEx("SelectedStatesVar", StatesList);

                //Save the workflow selected by the user

                mTaskProps.SetValEx("SelectedWorkflowVar", WorkflowsComboBox.Text);

                //Save the number of days selected by the user

                mTaskProps.SetValEx("NoDaysVar", DaysNumericUpDown.Text.ToString());



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





        private void WorkflowsComboBox_SelectedIndexChanged(System.Object sender, System.EventArgs e)

        {

            try

            {

                //Find the IEdmWorkflow corresponding to the

                //selected workflow name

                IEdmWorkflowMgr6 WorkflowMgr = default(IEdmWorkflowMgr6);

                WorkflowMgr = (IEdmWorkflowMgr6)mVault.CreateUtility(EdmUtility.EdmUtil_WorkflowMgr);

                IEdmPos5 WorkflowPos = WorkflowMgr.GetFirstWorkflowPosition();

                IEdmWorkflow6 Workflow = null;

                IEdmWorkflow6 SelectedWorkflow = null;

                while (!WorkflowPos.IsNull)

                {

                    Workflow = WorkflowMgr.GetNextWorkflow(WorkflowPos);

                    if (Workflow.Name == WorkflowsComboBox.Text)

                    {

                        SelectedWorkflow = Workflow;

                        break;

                    }

                }



                //Add the names of the available states for the

                //selected workflow to StatesListBox

                StatesListBox.Items.Clear();

                if (SelectedWorkflow != null)

                {

                    IEdmPos5 StatePos = SelectedWorkflow.GetFirstStatePosition();

                    while (!(StatePos.IsNull))

                    {

                        IEdmState6 State = default(IEdmState6);

                        State = SelectedWorkflow.GetNextState(StatePos);

                        StatesListBox.Items.Add(State.Name);



                    }



                }



                string SelectedStates = "";

                if ((mTaskProps != null))

                {

                    SelectedStates = (string)mTaskProps.GetValEx("SelectedStatesVar");

                }

                else if ((mTaskInst != null))

                {

                    SelectedStates = (string)mTaskInst.GetValEx("SelectedStatesVar");

                }



                string[] States = SelectedStates.Split(new string[] { "\\n" }, StringSplitOptions.None);

                foreach (string State in States)

                {

                    if (!string.IsNullOrEmpty(State.Trim()))

                    {

                        StatesListBox.SelectedItems.Add(State);

                    }

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



        public void DisableControls()

        {

            try

            {

                WorkflowsComboBox.Enabled = false;

                StatesListBox.Enabled = false;

                DaysNumericUpDown.Enabled = false;

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
    }
}
