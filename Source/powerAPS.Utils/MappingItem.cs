using System.ComponentModel;

namespace powerAPS.Utils
{
    public class MappingItem : INotifyPropertyChanged
    {
        private string _acc;
        private string _vault;

        public string Acc
        {
            get { return _acc; }
            set
            {
                if (_acc != value)
                {
                    _acc = value;
                    OnPropertyChanged("Acc");
                }
            }
        }

        public string Vault
        {
            get { return _vault; }
            set
            {
                if (_vault != value)
                {
                    _vault = value;
                    OnPropertyChanged("Vault");
                }
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected void OnPropertyChanged(string propertyName)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
            }
        }
    }
}