const app = new Vue({
    el: '#app',
    data: {
        nui:false,
        stockDatas: [],
        myDatas: [],
        buyDaysList: [],
        spinner: false,
        buyDay: false,
        sellDay: false,
    },
    methods: {
        close() {
            this.nui = false
            $.post(`https://cb-stockmarket/exit`, JSON.stringify({}));
        },
        buy(item) {
            this.spinner = true;
            setTimeout(() => {
                if (parseInt(item.buyAmount) > 0) {
                    $.post(`https://cb-stockmarket/buy`, JSON.stringify({ stock: item.name, count: parseInt(item.buyAmount) }), function(data) {
                        app.spinner = false;
                        if (data) {
                            Swal.fire(
                                'Transaction',
                                `You bougth ${item.buyAmount} ${item.name}`,
                                'success'
                            )
                            app.myDatas[item.name] = Number(app.myDatas[item.name]) + Number(item.buyAmount);
                        } else {
                            Swal.fire(
                                'Transcation Error',
                                'Not Enough Item Available In Stock',
                                'error'
                            );
                        }
                    });
                } else {
                    this.spinner = false;
                    Swal.fire(
                        'Input Error',
                        'Enter Amount',
                        'error'
                    );
                }
            }, 1000);
        },
        sell(item) {
            this.spinner = true;
            setTimeout(() => {
                if (parseInt(item.buyAmount) > 0 && Number(app.myDatas[item.name]) >= parseInt(item.buyAmount)) {
                    $.post(`https://cb-stockmarket/sell`, JSON.stringify({ stock: item.name, count: parseInt(item.buyAmount) }), function(data) {
                        app.spinner = false;
                        if (data) {
                            Swal.fire(
                                'Transaction',
                                `You sell ${item.buyAmount} ${item.name}`,
                                'success'
                            )
                            app.myDatas[item.name] = Number(app.myDatas[item.name]) - Number(item.buyAmount);
                            item.amount = Number(item.amount) + parseInt(item.buyAmount)
                        } else {
                            Swal.fire(
                                'Transcation Error',
                                'Not Enough Item Available',
                                'error'
                            );
                        }
                    });
                } else {
                    this.spinner = false;
                    Swal.fire(
                        'Input Error',
                        'Enter Amount',
                        'error'
                    );
                }
            }, 1000);
        }
    },
})

function getWeekName() {
    const weekNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const today = new Date();
    const dayOfWeek = today.getDay();
  
    return weekNames[dayOfWeek];
}

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.nui == "open"){
        app.spinner = false;
        app.nui = true;
        app.stockDatas = data.stock;
        app.myDatas = data.myDatas;
        app.buyDaysList = data.buyDays;
        data.buyDays[getWeekName()] ? app.buyDay = true : app.buyDay = false;
        data.sellDays[getWeekName()] ? app.sellDay = true : app.sellDay = false;
    } else if (data.nui == "update") {
        app.stockDatas = data.stock;
    }
    if(app.stockDatas) {
        for (let index = 0; index < app.stockDatas.length; index++) {
            app.stockDatas[index].buyAmount = 0  
        }
    }

})

document.onkeyup = function(data) {
    if (data.which == 27) { // Escape Key
        app.close();
    }
};