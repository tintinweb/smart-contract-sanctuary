/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.7;



// File: will.sol

// contract to create a will for contract owner, exectuors have "weighting".
// if weighting is > 1 for exectuors then decision sticks
contract Will {
    // map owner address to executor
    // map owner address to beneficiary address to value

    address owner; // contract owner

    event ReadWill(address willOwner, address beneficiary, uint256 value);
    event ExecutorAdded(
        address executor,
        uint256 index,
        uint256 weighting,
        uint256 numberOfExecutors
    );
    event ExecutorRemoved(
        address _executor,
        uint256 index,
        uint256 numberOfExecutors
    );

    event BeneficiaryEntitlement(
        address willOwner,
        address beneficiary,
        uint256
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //address[] testArray;
    address[] private beneficiaryAddresses;
    mapping(address => uint256) private beneficiaryWeiEntitlement;
    address[] private executors;
    mapping(address => uint256) public executorWeighting;
    mapping(address => uint256) private executorIndex;
    uint256 numberOfExecutors;
    uint256 executorTotalWeighting;

    constructor() {
        // the owner of the will is the one who creates it
        owner = msg.sender;
    }

    function isExecutor(address _executor) public returns (uint256) {
        return uint256(50); //executorWeighting[_executor];
    }

    function addExecutor(address _executor, uint256 _executorWeighting)
        public
        onlyOwner
    {
        // ensure that an executor who already exists isn't added
        require(
            executorWeighting[_executor] == 0,
            "Cannot add executor who already exists"
        );
        require(
            _executorWeighting > 0,
            "Executor must have have a non-zero weighting"
        );
        require(
            _executorWeighting <= 100,
            "Executor must hve a weighting less than 100"
        );

        // array that points to executor index (for weighitn etc)
        executorIndex[_executor] = executors.length;
        // add executor weighting to mapping
        executorWeighting[_executor] = _executorWeighting;
        // push executor address onto the array of executors
        executors.push(_executor);

        numberOfExecutors++;

        emit ExecutorAdded(
            _executor,
            executorIndex[_executor],
            _executorWeighting,
            numberOfExecutors
        );
    }

    function removeExecutor(address _executor) public onlyOwner {
        require(
            executorWeighting[_executor] != 0,
            "Executor cannot be removed - does not exist"
        );
        // we don't delete executors, we just set their weighting to zero
        executorWeighting[_executor] = 0;

        numberOfExecutors--;
        emit ExecutorRemoved(
            _executor,
            executorIndex[_executor],
            numberOfExecutors
        );
    }

    // function getExecutor(address _willOwner) public view returns (address) {
    //     return executor[_willOwner];
    // }

    // function addExecutor

    // // call this function with a value and a beneficiary
    // function addBeneficiary(address _beneficiary)
    //     public
    //     payable
    //     returns (bool)
    // {
    //     //        require(executor[msg.sender] != 0, "executor not set, will not created");
    //     require(msg.value > 0, "message value is zero");
    //     //        beneficiary[msg.sender][_beneficiary] = msg.value;

    //     // TODO: Check beneficiary doesn't already have an entitlement

    //     beneficiaryAddress[msg.sender].push(_beneficiary);
    //     beneficiaryWeiEntitlement[msg.sender][_beneficiary] = msg.value;

    //     // log the entitlement of the beneficiary
    //     emit BeneficiaryEntitlement(msg.sender, _beneficiary, msg.value);
    // }

    // // read the will, that is, distribute the funds
    // // ensure that only the executore of the will can call this
    // function distributeWill(address _willOwner) public {
    //     require(
    //         msg.sender == executor[_willOwner],
    //         "Only executor can distrirbute funds from the will"
    //     );
    //     for (uint256 i = 0; i < beneficiaryAddress[_willOwner].length; i++) {
    //         address _beneficiaryAddress;
    //         uint256 _beneficiaryWeiEntitlement;

    //         _beneficiaryAddress = beneficiaryAddress[_willOwner][i];
    //         _beneficiaryWeiEntitlement = beneficiaryWeiEntitlement[_willOwner][
    //             _beneficiaryAddress
    //         ];

    //         //

    //         (bool success, ) = _beneficiaryAddress.call{
    //             value: _beneficiaryWeiEntitlement
    //         }("");

    //         require(success, "Failed to send Ether");

    //         // beneficiary now has zero entitlement from this willOwner
    //         beneficiaryWeiEntitlement[_willOwner][_beneficiaryAddress] = 0;

    //         // log transfer
    //         emit ReadWill(
    //             _willOwner,
    //             _beneficiaryAddress,
    //             _beneficiaryWeiEntitlement
    //         );
    //         // log beneficiaries new entitlement (should be zero)

    //         require(
    //             beneficiaryWeiEntitlement[_willOwner][_beneficiaryAddress] == 0,
    //             "New beneficiary entitlement should be zero"
    //         );
    //         emit BeneficiaryEntitlement(
    //             _willOwner,
    //             _beneficiaryAddress,
    //             beneficiaryWeiEntitlement[_willOwner][_beneficiaryAddress]
    //         );
    //     }
    // }

    // function getBeneficiaries(address _willOwner) private {
    //     // ensure that only the willOwner or executor can call this function
    //     require(
    //         _willOwner == msg.sender ||
    //             beneficiaryAddress[_willOwner] == msg.sender
    //     );

    //     for (uint256 i = 0; i < beneficiaryAddress[_willOwner].length; i++) {
    //         address _beneficiaryAddress;
    //         uint256 _beneficiaryWeiEntitlement;

    //         _beneficiaryAddress = beneficiaryAddress[_willOwner][i];
    //         _beneficiaryWeiEntitlement = beneficiaryWeiEntitlement[_willOwner][
    //             _beneficiaryAddress
    //         ];

    //         emit BeneficiaryEntitlement(
    //             _willOwner,
    //             _beneficiaryAddress,
    //             beneficiaryWeiEntitlement[_willOwner][_beneficiaryAddress]
    //         );
    //     }
    // }
}