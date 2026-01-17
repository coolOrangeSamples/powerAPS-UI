using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace powerAPS.Utils
{
    public class TreeViewNode : INotifyPropertyChanged
    {
        public delegate void LoadChildrenHandler(object sender);
        public event LoadChildrenHandler LoadChildren;

        private readonly bool _isDummy;
        private string _name;
        private bool _isExpanded;
        private bool _isSelected;
        private TreeViewNode _parent;

        public event PropertyChangedEventHandler PropertyChanged;

        private void NotifyPropertyChanged([CallerMemberName] string propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public TreeViewNode()
        {
            _isDummy = true;
        }

        public TreeViewNode(TreeViewNode parent, bool isOutmost = false)
        {
            Parent = parent;
            if (isOutmost)
                Children = new ObservableCollection<TreeViewNode>();
            else
                Children = new ObservableCollection<TreeViewNode> { new TreeViewNode() };
        }

        public TreeViewNode Parent
        {
            get => _parent;
            set => _parent = value;
        }

        public ObservableCollection<TreeViewNode> Children { get; set; }

        public string Name
        {
            get => _name;
            set
            {
                if (value != _name)
                {
                    _name = value;
                    NotifyPropertyChanged();
                }
            }
        }

        public object Type { get; set; }

        public bool IsExpanded
        {
            get => _isExpanded;
            set
            {
                if (value != _isExpanded)
                {
                    _isExpanded = value;
                    NotifyPropertyChanged();

                    if (Children.Count == 1 && Children[0]._isDummy)
                    {
                        if (LoadChildren == null)
                            return;

                        Children.Clear();
                        LoadChildren(this);
                    }
                }

                if (_isExpanded && _parent != null)
                    _parent.IsExpanded = true;
            }
        }

        public bool IsSelected
        {
            get => _isSelected;
            set
            {
                if (value != _isSelected)
                {
                    _isSelected = value;
                    NotifyPropertyChanged();
                }
            }
        }

        public object Object { get; set; }
    }
}
