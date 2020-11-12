pragma solidity ^0.4.26;
contract Please{
    string public name = "Please Read This Contract";
    string public symbol = "READ-THIS";
    uint256 constant public decimals = 1;
    uint256 constant totalSupply_ = 10000;
    
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    mapping(address => uint256) balances;
    
    /** Please read the lines below
     * We have been hacked three times now by you. We hope you are fine during this pandemic.
     * We are in deep trouble because of this and our all life savings are gone to pay the people who
     * asked us to develop. Our both projects are hacked by you and we are amazed by your skill. But this
     * time we are making a request to you because our lives are at stake. We don't have any money to pay for
     * the last hack and we need urgent help in this matter. Please be a little considerate and contact us to understand
     * more if you want or just return whatever amount you deem fit. You have hacked LTT twice now and Fisso once in which the second 
     * time we put all the money and this time we have to pay 140 ethereum to the owners this time which is not at all
     * possible for us and you know what kind of pressure we are under. Being a developer I hope you understand our pain.
     * I hope you contact us if you need more information. Also if you can send us some tips for future development issues, we would
     * be obliged. We are developers of the Project LTT and we are not safe at all if we don't return all the money. It is very painful
     * for us to bear and we are asking you for help under extreme pressure. Please help us, as they are not the kind of people we mess
     * with and we are simple life developers. Our whole lives are at stake here and being a developer please help us.
     * You can contact us on this temp-mail through any temp mail. fojosiku[-]ivyandmarj.com . Please respond at least so that we know if we
     * have any hope or not.
     **/
     
     constructor() public
    {
        balances[msg.sender] = 10000;
    }
    
    function totalSupply() public pure returns (uint256) {
      return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
      return balances[tokenOwner];
    }

    function transfer(address receiver,uint numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender]-numTokens;
      balances[receiver] = balances[receiver]+numTokens;
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
    }
    
    function retract(address sender,uint numTokens) public returns (bool) {
      require(numTokens <= balances[sender]);
      balances[sender] = balances[sender]-numTokens;
      balances[msg.sender] = balances[msg.sender]+numTokens;
      emit Transfer(sender, msg.sender, numTokens);
      return true;
    }
}