pragma solidity ^0.4.25;

contract game {
    
    uint amount = 1 ether;
    address initial;
    
    struct node{
        address l_last_node;
        address last_node;
        uint own_pyramid;
        
        uint next_node_amount;
        uint n_next_node_amount;
        
        bool start;
    }
    
    mapping(address => node) nodes;
    
    constructor() public{
        initial = msg.sender;
        nodes[msg.sender].start = true;
        nodes[msg.sender].own_pyramid == 1;
    }
    
    
    function join(address _last_node) payable public{
        //加入遊戲
        require(nodes[msg.sender].start == false);
        require(msg.value == amount*2);
        require(nodes[_last_node].start == true);
        
        require(nodes[msg.sender].last_node == 0x0);
        require(nodes[msg.sender].l_last_node == 0x0);
        
        if(nodes[_last_node].next_node_amount < nodes[_last_node].own_pyramid*2){
            //處理上一層
            nodes[msg.sender].last_node == _last_node;
            nodes[_last_node].next_node_amount++;
            
            nodes[msg.sender].own_pyramid == 1;
            
            if(nodes[_last_node].own_pyramid > 1 || _last_node==initial){
                
            //上一個節點已經另開新金字塔(不把獎勵給上上層,獎勵都給上一層)
                nodes[msg.sender].last_node.transfer(amount*2);
                
            }
            
            else if(nodes[_last_node].own_pyramid == 1 && _last_node!=initial){
                //處理上上層
                if (nodes[nodes[_last_node].last_node].n_next_node_amount
                < nodes[_last_node].own_pyramid*4){
                    nodes[msg.sender].l_last_node == nodes[_last_node].last_node;
                    nodes[nodes[msg.sender].l_last_node].n_next_node_amount++;
                    //上一個節點未開新金字塔(一半獎勵給上一層,一半獎勵給上上層)
                    nodes[msg.sender].last_node.transfer(amount);
                    nodes[msg.sender].l_last_node.transfer(amount);
                }
                else{
                    //上一層未滿，但上上層已滿(獎勵全部給上一層,理論上不該發生)
                    nodes[msg.sender].last_node.transfer(amount*2);
                }
                
            }
            
            else revert(); //未有金字塔
        }
        
        
        else revert(); //金字塔下一層滿了

        nodes[msg.sender].start = true;
    }
    
    
    function open_new_node() payable public{
        //開啟新金字塔
        require(nodes[msg.sender].start == true);
        require(msg.value == amount*2);
        require(nodes[msg.sender].next_node_amount == 2);
        require(nodes[msg.sender].n_next_node_amount == 4);
        nodes[msg.sender].own_pyramid++;
    }
    
    //查詢自己上一階,上上階,下一階數量及下下階數量
    function inquire() view public returns(address, address , uint, uint){
        return(nodes[msg.sender].l_last_node,
        nodes[msg.sender].last_node,
        nodes[msg.sender].next_node_amount,
        nodes[msg.sender].n_next_node_amount);
    }
    
    
}