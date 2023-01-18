# Resolução do desafio CustomerSuccess Balancing

## What is the challenge?

The challenge is to create a system to balance customers for customer success. So some rules have to be respected such as: customer level, customer success level, how much each customer success can and cannot serve.

## How I solved?

Initially I thought I would order the customer data and customer success data, and then I would be able to work with this data. I thought this way first, because I realized that the inputs were disordered, so it was necessary to first order them based on the score and then start working with the data.

After this, we could move on to the balancing itself. Within the balancing algorithms we think of Round And Robbin, Hash, Minimum Connections and etc. But, the challenge is not about load balancing itself, but about clients based on score. This way, we thought of the following condition: For a customer success to receive a customer, the customer's score needs to be less than or equal to your score. However, this would not fit for all cases, because there was a possibility that a customer success would not receive a customer, so we needed to add one more condition: the customer's score must be higher than the previous customer success. This way we were able to create a match algorithm for customers and customer success.

After finalizing the selection of customers for the customer success, we then have to create a data grouping, so we can define which customer success received the most customers and return them. Therefore, we used ruby's `group_by` method to create this grouping, then sorting in descending order and choosing the first value, because it will generate two effects: transformation of a hash into an array, highest result first.

## How to run the test

In terminal, execute the commands below:

```
ruby customer_success_balancing.rb
```