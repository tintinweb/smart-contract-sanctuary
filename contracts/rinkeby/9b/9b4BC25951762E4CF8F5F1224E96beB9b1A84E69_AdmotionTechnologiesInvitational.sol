/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: WTF

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/** 
* Place your email addres into [Candidates] array to notify HR
* 
* hints:
*   you can use https://remix.ethereum.org/ or https://www.trufflesuite.com/ for deployments
*   you can use https://remix.ethereum.org/ or https://rinkeby.etherscan.io/ for interacting with contracts
*   you can use https://solidity-by-example.org/app/erc20/ tutorial for some information
*   you can use https://faucet.rinkeby.io/ to get free ETH for deployments and making transactions
* 
*   see you later ;)
*/
contract AdmotionTechnologiesInvitational{
    struct Candidate{
        address accountAddress;
        string email;// email address to contract with you
        string name;// your name or nickname 
        address _addressOfDeployedForTestToken;//address of test token that you must deploy into rinkeby ethereum network
    }
    
    event newCandidate(uint256);

    Candidate[] public candidates;

    function join(string calldata _email, string memory _name, address _addressOfDeployedForTestToken) public payable {
        require(msg.value == 0x499602D2, "msg.value incorrect");
        
        require(
            compareStrings(IERC20(_addressOfDeployedForTestToken).name(),  "IWANNAJOB") && // token must have name "IWANNAJOB"
            compareStrings(IERC20(_addressOfDeployedForTestToken).symbol(), "IWJ") && // token must have symbol "IWJ"
            IERC20(_addressOfDeployedForTestToken).balanceOf(msg.sender) == 1 && // you must have 1 token on your balance
            IERC20(_addressOfDeployedForTestToken).balanceOf(address(this)) == 1, // this contract must have 1 token on balance
        "you provide bad test token, requirenments not satisfied!");
        
        
        candidates.push(Candidate(msg.sender, _email, _name, _addressOfDeployedForTestToken));
        emit newCandidate(candidates.length -1);
    }
    
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
        //https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity/82739
    }

}