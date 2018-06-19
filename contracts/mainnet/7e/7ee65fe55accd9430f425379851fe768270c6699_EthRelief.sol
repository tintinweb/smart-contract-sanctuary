/*
 *      ##########################################
 *      ##########################################
 *      ###                                    ###
 *      ###          &#119823;&#119845;&#119834;&#119858; & &#119830;&#119842;&#119847; &#119812;&#119853;&#119841;&#119838;&#119851;          ###
 *      ###                 at                 ###
 *      ###          &#119812;&#119827;&#119815;&#119812;&#119825;&#119808;&#119813;&#119813;&#119819;&#119812;.&#119810;&#119822;&#119820;          ###
 *      ###                                    ###
 *      ##########################################
 *      ##########################################
 *
 *      Welcome to the temporary &#119812;&#119853;&#119841;&#119825;&#119838;&#119845;&#119842;&#119838;&#119839; contract. It&#39;s just
 *      a place-holder for now, with little functionality other 
 *      than being forward compatible with the first version of 
 *      the &#119812;&#119853;&#119841;&#119825;&#119838;&#119845;&#119842;&#119838;&#119839; contract in current development. 
 *
 *      This contract acts as a temporary store for the ether 
 *      raised each week from the ticket sales of &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;, 
 *      for the future funding of the charitable arm of the 
 *      enterprise. It is the nascent beginnings of a blockchain 
 *      portal for donations to good causes worldwide, driven by a 
 *      decentralized cadre of &#119819;&#119822;&#119827; token holders, forming part
 *      of a &#119811;&#119808;&#119822; who both own and run &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838; & &#119812;&#119853;&#119841;&#119825;&#119838;&#119845;&#119842;&#119838;&#119839;.
 * 
 *
 *                  &#119812;&#119857;&#119836;&#119842;&#119853;&#119842;&#119847;&#119840; &#119853;&#119842;&#119846;&#119838;&#119852; - &#119852;&#119853;&#119834;&#119858; &#119853;&#119854;&#119847;&#119838;&#119837;!
 *
 *
 *      Learn more and take part at &#119841;&#119853;&#119853;&#119849;&#119852;://&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119836;&#119848;&#119846;/&#119842;&#119836;&#119848;
 *      If you want to chat to us you have loads of options:
 *      On &#119827;&#119838;&#119845;&#119838;&#119840;&#119851;&#119834;&#119846; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119853;.&#119846;&#119838;/&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;
 *      Or on &#119827;&#119856;&#119842;&#119853;&#119853;&#119838;&#119851; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119853;&#119856;&#119842;&#119853;&#119853;&#119838;&#119851;.&#119836;&#119848;&#119846;/&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;
 *      Or on &#119825;&#119838;&#119837;&#119837;&#119842;&#119853; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119851;&#119838;&#119837;&#119837;&#119842;&#119853;.&#119836;&#119848;&#119846;
 *
 *
 *
 *                                  &#119812;&#119853;&#119841;&#119825;&#119838;&#119845;&#119842;&#119838;&#119839;  
 *      Building the largest source of decentralized altruism in the world!
 *
 *
 */
pragma solidity^0.4.21;

contract ReceiverInterface {
    function receiveEther() external payable {}
}

contract EthRelief {

    bool    upgraded;
    address etheraffle;
    /**
     * @dev  Modifier to prepend to functions rendering them
     *       only callable by the Etheraffle multisig address.
     */
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
    event LogEtherReceived(address fromWhere, uint howMuch, uint atTime);
    event LogUpgrade(address toWhere, uint amountTransferred, uint atTime);
    /**
     * @dev   Constructor - sets the etheraffle var to the Etheraffle
     *        managerial multisig account.
     *
     * @param _etheraffle   The Etheraffle multisig account.
     */
    function EthRelief(address _etheraffle) {
        etheraffle = _etheraffle;
    }
    /**
     * @dev   Upgrade function transferring all this contract&#39;s ether
     *        via the standard receive ether function in the proposed
     *        new disbursal contract.
     *
     * @param _addr    The new disbursal contract address.
     */
    function upgrade(address _addr) onlyEtheraffle external {
        upgraded = true;
        emit LogUpgrade(_addr, this.balance, now);
        ReceiverInterface(_addr).receiveEther.value(this.balance)();
    }
    /**
     * @dev   Standard receive ether function, forward-compatible
     *        with proposed future disbursal contract.
     */
    function receiveEther() payable external {
        emit LogEtherReceived(msg.sender, msg.value, now);
    }
    /**
     * @dev   Set the Etheraffle multisig contract address, in case of future
     *        upgrades. Only callable by the current Etheraffle address.
     *
     * @param _newAddr   New address of Etheraffle multisig contract.
     */
    function setEtheraffle(address _newAddr) onlyEtheraffle external {
        etheraffle = _newAddr;
    }
    /**
     * @dev   selfDestruct - used here to delete this placeholder contract
     *        and forward any funds sent to it on to the final EthRelief
     *        contract once it is fully developed. Only callable by the
     *        Etheraffle multisig.
     *
     * @param _addr   The destination address for any ether herein.
     */
    function selfDestruct(address _addr) onlyEtheraffle {
        require(upgraded);
        selfdestruct(_addr);
    }
    /**
     * @dev   Fallback function that accepts ether and announces it&#39;s
     *        arrival via an event.
     */
    function () payable external {
    }
}