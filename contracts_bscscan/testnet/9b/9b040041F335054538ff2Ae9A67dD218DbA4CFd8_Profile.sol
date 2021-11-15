// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Token {
 
    function transferFrom(address, address, uint) external returns (bool);

    function transfer(address, uint) external returns (bool);
}

interface IPancake {
          function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}
 

contract Profile {
    event save(address user, string data);
    mapping(address => mapping(uint256 => uint256)) public freeTransfers;
    mapping(address => uint256) public freeBalance;
    mapping(address => string) public profiles;
    mapping(address => string[]) public playersHistory;
    address feeTaker = 0x759C8682800fE744516C5E4CF85D19Df2C8eD72D ;
    // Router
    address public router =  0x10ED43C718714eb63d5aA57B78B54704E256024E ; 
    address public pairToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 ;
    address public mainToken = 0xa6188F620844641D2b9ecdbD47DBAf51ea452F9e ; 


    //  function getBaseTokenPrice() public view returns (uint256) {
    //     address[] memory  pair = new address[](2) ;
    //     pair[0] = pairToken ;
    //     pair[1] = mainToken ;
    //     uint[] memory _token = IPancake(router).getAmountsOut(1e18, pair);
    //     return _token[1] ;
    // }


  function getBaseTokenPrice() public view returns (uint256) {
        uint256   _token = 6827009070565183825;
        return _token ;
    }

    function saveProfile (string calldata _data) external{
        profiles[msg.sender] = _data;
        updateProfile(100,0) ;
        emit save(msg.sender,_data);
    }

    function getFreeBalance (address user) public view returns(uint256){
        return  freeBalance[user];
    }

    function getFreeTransfers (address user,uint256 _gameWeek) public view returns(uint256){
        return  freeTransfers[user][_gameWeek] ;
    }

 

    function updateProfile (uint256 _freebalance, uint256 _gameWeek) internal{
        freeBalance[msg.sender] = _freebalance ;
        if(_gameWeek > 0 ){
            freeTransfers[msg.sender][_gameWeek]++ ;
        }
              
    }

    function getcost(uint256 _cost) public view returns(uint256){
      uint256  cost = getBaseTokenPrice()*_cost/1e18 ;
        return cost ;
    }

    function updatePlayers (string calldata _data,uint256 _gameWeek, uint256 _freeBalance, uint256 _cost) external{
        require(freeTransfers[msg.sender][_gameWeek] < 2, "No More Transfers");
        if(_cost > 0 ){
            require(_freeBalance == 0, "Not Allowed");
            _cost = getBaseTokenPrice()*_cost/1e18 ;
            Token(mainToken).transferFrom(msg.sender,feeTaker,_cost);
        }
        updateProfile(_freeBalance,_gameWeek) ;
        playersHistory[msg.sender].push(_data);
    }

    function getPlayersHistory (
        address _address
    )
    external view returns (string[] memory)
    {
        string[] memory tempList = playersHistory[_address];
        return tempList;
    }
}

