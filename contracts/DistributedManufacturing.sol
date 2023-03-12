//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract DistributedManufacturing {
    enum Stage {
        not_started,
        machine1,
        machine2,
        machine3,
        machine4,
        machine5,
        finished
    }

    struct ProductDetails {
        uint256 uid;
        address owner;
        address[7] addresses;
        Stage stage;
    }

    uint256 public productCounter;

    mapping(uint256 => ProductDetails) public productDetailsMap;
    uint256[5] public rateChart;

    constructor() {
        rateChart[0] = 1000;
        rateChart[1] = 2000;
        rateChart[2] = 3000;
        rateChart[3] = 4000;
        rateChart[4] = 5000;
    }

    function addProduct(
        address not_started,
        address machine1,
        address machine2,
        address machine3,
        address machine4,
        address machine5,
        address finished
    ) public payable returns (uint256) {
        uint256 cost = 0;
        address[7] memory _addresses = [
            not_started,
            machine1,
            machine2,
            machine3,
            machine4,
            machine5,
            finished
        ];

        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) {
                cost += rateChart[i - 1];
            }
        }

        require(msg.value >= cost, "Insufficient payment");
        productCounter++;
        productDetailsMap[productCounter] = ProductDetails(
            productCounter,
            msg.sender,
            _addresses,
            Stage.not_started
        );
        return productCounter;
    }

    function acceptOrder(uint256 _productId, uint256 machineIndex) public {
        require(
            machineIndex < productDetailsMap[_productId].addresses.length,
            "Index out of range"
        );
        require(
            productDetailsMap[_productId].addresses[machineIndex] == address(0),
            "Address already set on FCFS basis."
        );

        productDetailsMap[_productId].addresses[machineIndex] = msg.sender;
    }

    function sendNextMachine(uint256 _productId) external payable returns (uint256)  {
        
        ProductDetails storage product = productDetailsMap[_productId];
        require(product.stage != Stage.finished, "Product already finished");
        
        uint256 currentStageIndex = uint256(product.stage);

        address payable senderAddress = payable(msg.sender);
        address currentMachineAdress = product.addresses[currentStageIndex];
        
        require(senderAddress == currentMachineAdress, "Sender is not current machine owner" );

        if(senderAddress != product.owner) {
            uint256 transferAmount = rateChart[currentStageIndex - 1];
            require (transferAmount <= address(this).balance, "Insufficient contract balance");
            senderAddress.transfer(transferAmount);
        }

        
        
        product.stage = Stage(currentStageIndex + 1);

        return address(this).balance;
    }
}
