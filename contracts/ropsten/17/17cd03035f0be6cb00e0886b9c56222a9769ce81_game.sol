pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor()public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract game is owned{
    
    bool stop = false;
    uint amount = 1 ether;
    uint fee = 0.2 ether;
    
    address public initial;
    
    struct node{
        address l_l_last_node;
        address l_last_node;
        address last_node;

        uint next_node_amount;
        uint n_next_node_amount;
        uint n_n_next_node_amount;
        
        bool start;
    }
    
    mapping(address => node) nodes;
    
    event Join(address indexed last_node, address indexed next_node);
    
    constructor() public{
        initial = msg.sender;
        nodes[msg.sender].start = true;
        
    }
    
    //管理權限
    
    function withdraw()public onlyOwner{
        owner.transfer(address(this).balance);
    }
    
    function set_stop(bool _stop) public onlyOwner{
        stop = _stop;
    }
    
    //遊戲外部function
    
    function join(address _last_node) payable public{
        //加入遊戲
        require(stop == false);
        require(_last_node != msg.sender);
        require(nodes[msg.sender].start == false);
        require(msg.value == (amount*3+fee) );
        require(nodes[_last_node].start == true);
        
        require(nodes[msg.sender].last_node == 0x0);
        require(nodes[msg.sender].l_last_node == 0x0);
        require(nodes[msg.sender].l_l_last_node == 0x0);
        
        if(nodes[_last_node].next_node_amount < 3){
            //處理上一層
            nodes[msg.sender].last_node = _last_node;
            nodes[_last_node].next_node_amount++;
            
            if(_last_node==initial){
                
            //上一個節點已經另開新金字塔(不把獎勵給上上層,獎勵都給上一層)
                nodes[msg.sender].last_node.transfer(amount*2);
                
            }
            
            else{
                //處理上上層
                if (nodes[nodes[_last_node].last_node].n_next_node_amount < 9){
                    
                    nodes[msg.sender].l_last_node = nodes[_last_node].last_node;
                    nodes[nodes[msg.sender].l_last_node].n_next_node_amount++;
                    
                    //上一個節點未開新金字塔(一半獎勵給上一層,一半獎勵給上上層)
                    nodes[msg.sender].last_node.transfer(amount);
                    nodes[msg.sender].l_last_node.transfer(amount);
                    nodes[msg.sender].l_l_last_node.transfer(amount);
                }
                else{
                    //上一層未滿，但上上層已滿(獎勵全部給上一層,理論上不該發生)
                    nodes[msg.sender].last_node.transfer(amount*2);
                }
            }
                if (nodes[nodes[_last_node].last_node].n_n_next_node_amount < 27){
                    
                    nodes[msg.sender].l_l_last_node = nodes[_last_node].l_last_node;
                    nodes[nodes[msg.sender].l_l_last_node].n_n_next_node_amount++;
                    
                    //上一個節點未開新金字塔(一半獎勵給上一層,一半獎勵給上上層)
                    nodes[msg.sender].last_node.transfer(amount);
                    nodes[msg.sender].l_last_node.transfer(amount);
                    nodes[msg.sender].l_l_last_node.transfer(amount);
                }

            
        }
        
        else revert(); //金字塔下一層滿了()

        nodes[msg.sender].start = true;
        emit Join(_last_node, msg.sender);
    }
    
    //查詢自己上一階,上上階,下一階數量及下下階數量
    function inquire() view public returns(address, address , uint, uint){(
        nodes[msg.sender].l_l_last_node,
        nodes[msg.sender].l_last_node,
        nodes[msg.sender].last_node,
        nodes[msg.sender].next_node_amount,
        nodes[msg.sender].n_next_node_amount,
        nodes[msg.sender].n_n_next_node_amount);
    }
    
    
}