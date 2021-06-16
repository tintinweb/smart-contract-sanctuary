/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.25;





contract UNFIAggregator  {
  

    string private _name  = "Aggregator UNFI";
    string private _symbol  = "aUNFI";
    uint8 private _decimals = 18 ;
GGM lvl1;
GGM lvl2;
GGM lvl3 = GGM(0xf64a670a3F1E877031e9a62f2E382E4b2035b620);
IERC20 lvl4 = IERC20(0x441761326490cACF7aF299725B6292597EE822c2);
    address public _owner ;
    mapping(uint =>bool) public enableVotes;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;


    constructor () public {
        _owner = msg.sender;
    }





    /**
     * @return the name of the token.
     */
    function name() public view returns (string) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
 


    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256 totalSupplyResult) {
         totalSupplyResult = lvl4.totalSupply();
        if(enableVotes[1] == true && address(lvl1) != address(0) ){
            totalSupplyResult = totalSupplyResult + (lvl1.totalStakeAmount());
        }
        if(enableVotes[2] == true  && address(lvl2) != address(0)){
            totalSupplyResult = totalSupplyResult + (lvl2.totalStakeAmount());    
        }
        if(enableVotes[3] == true  && address(lvl3) != address(0) ){
            totalSupplyResult = totalSupplyResult + (lvl3.totalStakeAmount());
        }
        return totalSupplyResult;
    }



    function balanceOf(address account) public view returns (uint256 balanceResult) {
         balanceResult = lvl4.balanceOf(account );
        if(enableVotes[1] == true && address(lvl1) != address(0) ){
            balanceResult = balanceResult + (lvl1.userStakeAmount(account));
        }
        if(enableVotes[2] == true  && address(lvl2) != address(0)){
            balanceResult = balanceResult + (lvl2.userStakeAmount(account));    
        }
        if(enableVotes[3] == true  && address(lvl3) != address(0) ){
            balanceResult = balanceResult + (lvl3.userStakeAmount(account));
        }
        return balanceResult;
    
    }
   
  function updatGGMDetals (uint GGMLevel, bool value , address GGMAddress)public {
      require(_owner == msg.sender,"Unauthorized");
      if(GGMLevel == 1){
          enableVotes[1] = value;
           lvl1 = GGM(GGMAddress);
      }

      if(GGMLevel == 2){
           enableVotes[2] = value; 
            lvl2 = GGM(GGMAddress);
      }
      
      if(GGMLevel == 3){
          enableVotes[3] = value;
            lvl3 = GGM(GGMAddress);
      }
      
      if(GGMLevel == 4){
          enableVotes[4] = value;  
          lvl4 = IERC20(GGMAddress);
      }
  }
    function transferOwnerShip(address to) public returns (bool) {
         require(_owner == msg.sender,"Unauthorized");
         _owner = to;
        return true;
    }


  

  



   

}

pragma solidity ^0.4.25;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

pragma solidity ^0.4.25;


interface GGM {

    function totalStakeAmount() external view returns (uint256);
    function userStakeAmount(address account) external view returns (uint256);



}