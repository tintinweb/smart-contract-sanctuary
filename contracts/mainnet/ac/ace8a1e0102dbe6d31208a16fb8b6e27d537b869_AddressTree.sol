pragma solidity ^0.4.24;

contract Owned {
    address public owner;
    address public ownerCandidate;

    constructor() public {
        owner = address(0x6b9E41bE828027Bf199b9bC4167A31566daB6B62); 
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

contract AddressTree is Owned{
    
    // Max number of items in tree 
    uint256 public constant TreeLim = 2;
    
    struct Tree{
        mapping(uint256 => Tree) Items;
        address Item;
    }
    
    mapping(address => Tree) public TreeList; 
    
    function CheckTree(address root)
        internal
    {
        Tree storage CurrentTree = TreeList[root];
        if (CurrentTree.Item == address(0x0)){
            // empty tree 
            CurrentTree.Item = root;
        }

    }
    
    constructor()
        public
    {
    }
    
    
    function AddItem(address root, address target)
        public
        onlyOwner
    {
        CheckTree(root);
        CheckTree(target);
        Tree storage CurrentTree = TreeList[root];
        for (uint256 i=0; i<TreeLim; i++){
            if (CurrentTree.Items[i].Item == address(0x0)){
                
                Tree storage TargetTree = TreeList[target];
                CurrentTree.Items[i] = TargetTree;
                return;
            }
        }
        // no empty item found 
        revert();
    }
    
    function SetItem(address root, uint256 index, address target)
        public    
        onlyOwner
    {
        require(index < TreeLim);
        CheckTree(root);
        CheckTree(target);
        Tree storage CurrentTree = TreeList[root];
        Tree storage TargetTree = TreeList[target];
        CurrentTree.Items[index] = TargetTree;
        
    }
    
    //web view item
    function GetItems(address target)
        view
        public
        returns (address[TreeLim])
    {
        address[TreeLim] memory toReturn;
        Tree storage CurrentTree = TreeList[target];
        for (uint256 i=0; i<TreeLim; i++){
            toReturn[i] = CurrentTree.Items[i].Item;
        }
        return toReturn;
    }
    
    
}