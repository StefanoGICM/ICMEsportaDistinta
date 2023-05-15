using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static ICM.SWPDM.EsportaDistintaAddin.EsportaDistintaForm;

namespace ICM.SWPDM.EsportaDistintaAddin
{
    partial class EsportaDistinta : INotifyPropertyChanged
    {
        private long numberOfDocuments;
        public long NumberOfDocuments
        {
            get { return numberOfDocuments; }
            set
            {
                numberOfDocuments = value;
                InvokePropertyChanged(new PropertyChangedEventArgs("NumberOfDocuments"));
            }
        }

        private enumDocumentAnalysisStatus documentsAnalyzed;
        public enumDocumentAnalysisStatus DocumentsAnalysisStatus
        {
            get { return documentsAnalyzed; }
            set
            {
                documentsAnalyzed = value;
                InvokePropertyChanged(new PropertyChangedEventArgs("DocumentsAnalyzed"));

            }
        }

        

        #region Implementation of INotifyPropertyChanged

        public event PropertyChangedEventHandler PropertyChanged;

        public void InvokePropertyChanged(PropertyChangedEventArgs e)
        {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) handler(this, e);
        }

        #endregion
    }
}

