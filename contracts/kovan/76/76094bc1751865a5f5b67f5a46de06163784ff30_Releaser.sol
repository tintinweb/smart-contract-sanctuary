/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity ^0.8.0;
///SPDX-License-Identifier: UNLICENSED

contract Releaser {
    
    struct ReleaseType
     {  uint256 startTime;
        uint256 endTime  ;
        uint256 totalAmountOfToken ;
     }

    struct Beneficiary
     {  uint8   releaseType;           // public sale, seed round ...
        uint256 tokensAlreadyReleased;
        uint256 tokenBookedAmount;
     }

    uint8 constant PUBLIC_SALE         = 0;
    uint8 constant SEED_ROUND          = 1;
    uint8 constant TEAM1_CONTRIBUTORS  = 2;
    uint8 constant PRIVATE_ROUND       = 3;
    uint8 constant COINWEB_HOLDING     = 4;
    uint8 constant TEAM2_CONSTRIBUTOS  = 5;
    uint8 constant MINING_RESERVE      = 6;


    ReleaseType[7]                  public tokenomic;
    uint256[7]                      public avaliableTokensToRelease;
    IERC20                          public tokenContract;
    mapping(address => Beneficiary) public beneficiaries;
    uint256                         public creationTime;
    
    function setTokenomics() private{

        tokenomic[ PUBLIC_SALE        ] = ReleaseType(  0*3 hours,   0*3 hours,        10);
        tokenomic[ SEED_ROUND         ] = ReleaseType(  0*3 hours,  24*3 hours,       100);
        tokenomic[ TEAM1_CONTRIBUTORS ] = ReleaseType(  6*3 hours,  60*3 hours,      1000);
        tokenomic[ PRIVATE_ROUND      ] = ReleaseType(  0*3 hours,  12*3 hours,     10000);
        tokenomic[ COINWEB_HOLDING    ] = ReleaseType(  0*3 hours,  36*3 hours,    100000);
        tokenomic[ TEAM2_CONSTRIBUTOS ] = ReleaseType( 12*3 hours,  36*3 hours,   1000000);
        tokenomic[ MINING_RESERVE     ] = ReleaseType(  0*3 hours, 120*3 hours,   7680000000 - 1111110);


         
         
        for(uint8 i = 0; i < 7; i++){
             avaliableTokensToRelease[i] = tokenomic[i].totalAmountOfToken * (10 ** 18);
        }
        
        creationTime = block.timestamp;

    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function releaseToken() public{
        Beneficiary memory beneficiary    = beneficiaries[msg.sender];
        ReleaseType memory releaseType    = tokenomic[beneficiary.releaseType];
        
        uint256            sinceStart     = 0;
        
        if (block.timestamp >= releaseType.startTime){
            sinceStart = block.timestamp - releaseType.startTime;
        }
        
        if (sinceStart >= releaseType.endTime){
            sinceStart = releaseType.endTime;
        }

        // add +1 second to every start and end time to avoid dividing by zero.
        uint256     unlockedTokens = ((sinceStart + 1)* beneficiary.tokenBookedAmount) / (releaseType.endTime + 1);
        uint256     toRelease      =  unlockedTokens - beneficiary.tokensAlreadyReleased;
        
        beneficiaries[msg.sender].tokensAlreadyReleased += toRelease;
        
        tokenContract.transfer( msg.sender, toRelease );
        
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    address public adminA;
    address public adminB;
    
    modifier adminOnly(){
        require( (msg.sender == adminA) || (msg.sender == adminB)
               , 'Only admins allowed'
               )
        ;
        _;
    }

    function changeAdminB(address newAdminB) public adminOnly{
        adminB = newAdminB;
    }

    function changeAdminA(address newAdminA) public adminOnly{
        adminA = newAdminA;
    }

    function bookTokensFor( address beneficiary , uint256 tokenAmount, uint8 releaseType ) public adminOnly{
        require( avaliableTokensToRelease[releaseType] >= tokenAmount 
               , 'Not enough token to book'
               )
        ;
        require( beneficiaries[beneficiary].tokenBookedAmount != 0
               , 'Beneficiaries can only be set once'
               )
        ;
        avaliableTokensToRelease[releaseType] -= tokenAmount;
        
        beneficiaries[beneficiary] = Beneficiary(releaseType,0,tokenAmount);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    
    constructor(address _adminA, address _adminB, IERC20 _contract){
        tokenContract  = _contract;
        adminA         = _adminA;
        adminB         = _adminB;
        setTokenomics();
    }

}



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}