namespace ICM.SWPDM.EsportaDistintaAddin
{
    partial class SetupPage
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.confTextBox = new System.Windows.Forms.TextBox();
            this.confLabel = new System.Windows.Forms.Label();
            this.assiemeTextBox = new System.Windows.Forms.TextBox();
            this.assiemeLabel = new System.Windows.Forms.Label();
            this.padreLabel = new System.Windows.Forms.Label();
            this.padreListBox = new System.Windows.Forms.ListBox();
            this.figliLabel = new System.Windows.Forms.Label();
            this.figliListBox = new System.Windows.Forms.ListBox();
            this.topLevelCheckBox = new System.Windows.Forms.CheckBox();
            this.cancellaCheckBox = new System.Windows.Forms.CheckBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.listBox1 = new System.Windows.Forms.ListBox();
            this.outputGroupBox = new System.Windows.Forms.GroupBox();
            this.connARCALabel = new System.Windows.Forms.Label();
            this.ConnARCATextBox = new System.Windows.Forms.TextBox();
            this.ConnICMSWDataTextBox = new System.Windows.Forms.TextBox();
            this.ICMSWDataLabel = new System.Windows.Forms.Label();
            this.dirFileXMLTextBox = new System.Windows.Forms.TextBox();
            this.dirFileXMLLabel = new System.Windows.Forms.Label();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.noteTextBox = new System.Windows.Forms.TextBox();
            this.noteLabel = new System.Windows.Forms.Label();
            this.groupBox1.SuspendLayout();
            this.outputGroupBox.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            // 
            // confTextBox
            // 
            this.confTextBox.Location = new System.Drawing.Point(64, 119);
            this.confTextBox.Name = "confTextBox";
            this.confTextBox.Size = new System.Drawing.Size(1327, 26);
            this.confTextBox.TabIndex = 0;
            // 
            // confLabel
            // 
            this.confLabel.AutoSize = true;
            this.confLabel.Location = new System.Drawing.Point(62, 96);
            this.confLabel.Name = "confLabel";
            this.confLabel.Size = new System.Drawing.Size(208, 20);
            this.confLabel.TabIndex = 1;
            this.confLabel.Text = "Configurazioni da esportare:";
            // 
            // assiemeTextBox
            // 
            this.assiemeTextBox.Location = new System.Drawing.Point(66, 56);
            this.assiemeTextBox.Name = "assiemeTextBox";
            this.assiemeTextBox.Size = new System.Drawing.Size(913, 26);
            this.assiemeTextBox.TabIndex = 2;
            // 
            // assiemeLabel
            // 
            this.assiemeLabel.AutoSize = true;
            this.assiemeLabel.Location = new System.Drawing.Point(65, 28);
            this.assiemeLabel.Name = "assiemeLabel";
            this.assiemeLabel.Size = new System.Drawing.Size(168, 20);
            this.assiemeLabel.TabIndex = 3;
            this.assiemeLabel.Text = "Assieme da esportare:";
            // 
            // padreLabel
            // 
            this.padreLabel.AutoSize = true;
            this.padreLabel.Location = new System.Drawing.Point(60, 169);
            this.padreLabel.Name = "padreLabel";
            this.padreLabel.Size = new System.Drawing.Size(109, 20);
            this.padreLabel.TabIndex = 4;
            this.padreLabel.Text = "Padre/Radice:";
            // 
            // padreListBox
            // 
            this.padreListBox.FormattingEnabled = true;
            this.padreListBox.ItemHeight = 20;
            this.padreListBox.Items.AddRange(new object[] {
            "Ultima Versione",
            "Ultima Revisione",
            "Selezione Versione"});
            this.padreListBox.Location = new System.Drawing.Point(171, 169);
            this.padreListBox.Name = "padreListBox";
            this.padreListBox.Size = new System.Drawing.Size(146, 84);
            this.padreListBox.TabIndex = 5;
            // 
            // figliLabel
            // 
            this.figliLabel.AutoSize = true;
            this.figliLabel.Location = new System.Drawing.Point(544, 169);
            this.figliLabel.Name = "figliLabel";
            this.figliLabel.Size = new System.Drawing.Size(41, 20);
            this.figliLabel.TabIndex = 6;
            this.figliLabel.Text = "Figli:";
            // 
            // figliListBox
            // 
            this.figliListBox.FormattingEnabled = true;
            this.figliListBox.ItemHeight = 20;
            this.figliListBox.Items.AddRange(new object[] {
            "Ultima Versione",
            "Ultima Revisione",
            "Come Costruiti"});
            this.figliListBox.Location = new System.Drawing.Point(587, 169);
            this.figliListBox.Name = "figliListBox";
            this.figliListBox.Size = new System.Drawing.Size(136, 84);
            this.figliListBox.TabIndex = 7;
            this.figliListBox.SelectedIndexChanged += new System.EventHandler(this.listBox1_SelectedIndexChanged);
            // 
            // topLevelCheckBox
            // 
            this.topLevelCheckBox.AutoSize = true;
            this.topLevelCheckBox.Location = new System.Drawing.Point(28, 29);
            this.topLevelCheckBox.Name = "topLevelCheckBox";
            this.topLevelCheckBox.Size = new System.Drawing.Size(151, 24);
            this.topLevelCheckBox.TabIndex = 8;
            this.topLevelCheckBox.Text = "Solo primo livello";
            this.topLevelCheckBox.UseVisualStyleBackColor = true;
            // 
            // cancellaCheckBox
            // 
            this.cancellaCheckBox.AutoSize = true;
            this.cancellaCheckBox.Location = new System.Drawing.Point(28, 59);
            this.cancellaCheckBox.Name = "cancellaCheckBox";
            this.cancellaCheckBox.Size = new System.Drawing.Size(226, 24);
            this.cancellaCheckBox.TabIndex = 9;
            this.cancellaCheckBox.Text = "Cancella tabelle di frontiera";
            this.cancellaCheckBox.UseVisualStyleBackColor = true;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.cancellaCheckBox);
            this.groupBox1.Controls.Add(this.topLevelCheckBox);
            this.groupBox1.Location = new System.Drawing.Point(910, 163);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(285, 102);
            this.groupBox1.TabIndex = 10;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Opzioni";
            // 
            // listBox1
            // 
            this.listBox1.FormattingEnabled = true;
            this.listBox1.ItemHeight = 20;
            this.listBox1.Items.AddRange(new object[] {
            "ARCA",
            "File XML",
            "Tabella di Forntiera"});
            this.listBox1.Location = new System.Drawing.Point(71, 25);
            this.listBox1.Name = "listBox1";
            this.listBox1.Size = new System.Drawing.Size(146, 144);
            this.listBox1.TabIndex = 11;
            // 
            // outputGroupBox
            // 
            this.outputGroupBox.Controls.Add(this.groupBox2);
            this.outputGroupBox.Controls.Add(this.listBox1);
            this.outputGroupBox.Location = new System.Drawing.Point(65, 296);
            this.outputGroupBox.Name = "outputGroupBox";
            this.outputGroupBox.Size = new System.Drawing.Size(289, 192);
            this.outputGroupBox.TabIndex = 12;
            this.outputGroupBox.TabStop = false;
            this.outputGroupBox.Text = "Output";
            // 
            // connARCALabel
            // 
            this.connARCALabel.AutoSize = true;
            this.connARCALabel.Location = new System.Drawing.Point(4, 24);
            this.connARCALabel.Name = "connARCALabel";
            this.connARCALabel.Size = new System.Drawing.Size(191, 20);
            this.connARCALabel.TabIndex = 13;
            this.connARCALabel.Text = "Connessione SQL ARCA:";
            // 
            // ConnARCATextBox
            // 
            this.ConnARCATextBox.Location = new System.Drawing.Point(203, 21);
            this.ConnARCATextBox.Name = "ConnARCATextBox";
            this.ConnARCATextBox.Size = new System.Drawing.Size(839, 26);
            this.ConnARCATextBox.TabIndex = 12;
            // 
            // ConnICMSWDataTextBox
            // 
            this.ConnICMSWDataTextBox.Location = new System.Drawing.Point(309, 526);
            this.ConnICMSWDataTextBox.Name = "ConnICMSWDataTextBox";
            this.ConnICMSWDataTextBox.Size = new System.Drawing.Size(1044, 26);
            this.ConnICMSWDataTextBox.TabIndex = 14;
            // 
            // ICMSWDataLabel
            // 
            this.ICMSWDataLabel.AutoSize = true;
            this.ICMSWDataLabel.Location = new System.Drawing.Point(71, 526);
            this.ICMSWDataLabel.Name = "ICMSWDataLabel";
            this.ICMSWDataLabel.Size = new System.Drawing.Size(236, 20);
            this.ICMSWDataLabel.TabIndex = 15;
            this.ICMSWDataLabel.Text = "Connessione tabelle di frontiera:";
            // 
            // dirFileXMLTextBox
            // 
            this.dirFileXMLTextBox.Location = new System.Drawing.Point(203, 60);
            this.dirFileXMLTextBox.Name = "dirFileXMLTextBox";
            this.dirFileXMLTextBox.Size = new System.Drawing.Size(839, 26);
            this.dirFileXMLTextBox.TabIndex = 16;
            // 
            // dirFileXMLLabel
            // 
            this.dirFileXMLLabel.AutoSize = true;
            this.dirFileXMLLabel.Location = new System.Drawing.Point(53, 63);
            this.dirFileXMLLabel.Name = "dirFileXMLLabel";
            this.dirFileXMLLabel.Size = new System.Drawing.Size(142, 20);
            this.dirFileXMLLabel.TabIndex = 17;
            this.dirFileXMLLabel.Text = "Directory File XML:";
            // 
            // groupBox2
            // 
            this.groupBox2.Location = new System.Drawing.Point(288, 43);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(1083, 107);
            this.groupBox2.TabIndex = 12;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "groupBox2";
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.dirFileXMLLabel);
            this.groupBox3.Controls.Add(this.dirFileXMLTextBox);
            this.groupBox3.Controls.Add(this.connARCALabel);
            this.groupBox3.Controls.Add(this.ConnARCATextBox);
            this.groupBox3.Location = new System.Drawing.Point(372, 339);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(1063, 106);
            this.groupBox3.TabIndex = 18;
            this.groupBox3.TabStop = false;
            // 
            // noteTextBox
            // 
            this.noteTextBox.Location = new System.Drawing.Point(309, 579);
            this.noteTextBox.Name = "noteTextBox";
            this.noteTextBox.Size = new System.Drawing.Size(1044, 26);
            this.noteTextBox.TabIndex = 19;
            // 
            // noteLabel
            // 
            this.noteLabel.AutoSize = true;
            this.noteLabel.Location = new System.Drawing.Point(258, 586);
            this.noteLabel.Name = "noteLabel";
            this.noteLabel.Size = new System.Drawing.Size(47, 20);
            this.noteLabel.TabIndex = 20;
            this.noteLabel.Text = "Note:";
            // 
            // SetupPage
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(9F, 20F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.noteLabel);
            this.Controls.Add(this.noteTextBox);
            this.Controls.Add(this.groupBox3);
            this.Controls.Add(this.ICMSWDataLabel);
            this.Controls.Add(this.ConnICMSWDataTextBox);
            this.Controls.Add(this.outputGroupBox);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.figliListBox);
            this.Controls.Add(this.figliLabel);
            this.Controls.Add(this.padreLabel);
            this.Controls.Add(this.assiemeLabel);
            this.Controls.Add(this.assiemeTextBox);
            this.Controls.Add(this.confLabel);
            this.Controls.Add(this.confTextBox);
            this.Controls.Add(this.padreListBox);
            this.Name = "SetupPage";
            this.Size = new System.Drawing.Size(1518, 743);
            this.Load += new System.EventHandler(this.SetupPage_Load);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.outputGroupBox.ResumeLayout(false);
            this.groupBox3.ResumeLayout(false);
            this.groupBox3.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox confTextBox;
        private System.Windows.Forms.Label confLabel;
        private System.Windows.Forms.TextBox assiemeTextBox;
        private System.Windows.Forms.Label assiemeLabel;
        private System.Windows.Forms.Label padreLabel;
        private System.Windows.Forms.ListBox padreListBox;
        private System.Windows.Forms.Label figliLabel;
        private System.Windows.Forms.ListBox figliListBox;
        private System.Windows.Forms.CheckBox topLevelCheckBox;
        private System.Windows.Forms.CheckBox cancellaCheckBox;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.ListBox listBox1;
        private System.Windows.Forms.GroupBox outputGroupBox;
        private System.Windows.Forms.Label connARCALabel;
        private System.Windows.Forms.TextBox ConnARCATextBox;
        private System.Windows.Forms.TextBox ConnICMSWDataTextBox;
        private System.Windows.Forms.Label ICMSWDataLabel;
        private System.Windows.Forms.TextBox dirFileXMLTextBox;
        private System.Windows.Forms.Label dirFileXMLLabel;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.TextBox noteTextBox;
        private System.Windows.Forms.Label noteLabel;
    }
}
