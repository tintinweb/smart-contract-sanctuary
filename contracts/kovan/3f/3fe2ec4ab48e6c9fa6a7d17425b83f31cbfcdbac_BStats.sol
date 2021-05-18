/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-05
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/



pragma solidity ^0.5.16;

interface BCdpManagerLike {
    function cdpi() external view returns(uint);
    function urns(uint cdp) external view returns(address);
    function ilks(uint cdp) external view returns(bytes32);
    function vat() external view returns(address);
}

interface VatLike {
    function urns(bytes32 ilk, address urn) external view returns(uint ink, uint art);
}

contract BStats {
    function getStats(BCdpManagerLike man) external view returns(uint cdpi, uint eth, uint dai) {
        cdpi = man.cdpi();
        address vat = man.vat();        
        for(uint cdp = 1 ; cdp <= cdpi ; cdp++) {
            address urn = man.urns(cdp);            
            bytes32 ilk = man.ilks(cdp);
            (uint ink, uint art) = VatLike(vat).urns(ilk, urn);
            eth += ink;
            dai += art;
        }
    }
}