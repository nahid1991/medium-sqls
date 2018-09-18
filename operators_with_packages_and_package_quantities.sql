select operators.id,
       concat(users.first_name, ' ', users.last_name)    as operator_name,
       users.email,
       operators.alternative_email,
       string_agg(t2.name, ',')                          as package_name,
       string_agg(coalesce(bt.total_sales, '0'), ',')    as total_package_sales,
       string_agg(coalesce(bt.operator_sales, '0'), ',') as total_package_operator_sales,
       string_agg(coalesce(bt.profit, '0'), ',')         as package_profit,
       string_agg(pq.title, ';')                 as package_quantities,
       string_agg(coalesce(pq.total_quantity_sales, '0'), ';')    as total_quantity_sales,
       string_agg(coalesce(pq.operator_quantity_sales, '0'), ';') as operator_quantity_sales,
       string_agg(coalesce(pq.quantity_profit, '0'), ';')         as quantity_profit
from operators
       join users on users.id = operators.user_id
       join tour_packages on tour_packages.operator_id = operators.id
       join (select id, name, tour_package_id from tour_package_translations where locale = 'en')
    t2 on tour_packages.id = t2.tour_package_id
       left join (select cast(tour_packages.id as varchar)                                     as package_id,
                         cast(sum(coalesce(booking_tours.tour_total_price, 0)) as varchar)     as total_sales,
                         cast(sum(coalesce(booking_tours.total_operator_price, 0)) as varchar) as operator_sales,
                         cast(sum(coalesce(booking_tours.tour_total_price, 0)) -
                              sum(coalesce(booking_tours.total_operator_price, 0)) as varchar) as profit
                  from booking_tours
                         right join tour_packages on tour_packages.id = booking_tours.package_id
                  group by tour_packages.id, booking_tours.package_id) as
    bt on cast(bt.package_id as integer) = tour_packages.id
       join (select package_quantities.package_id,
                    string_agg(package_quantities.title, ',')          as title,
                    string_agg(coalesce(btq.total_quantity_sales, '0'), ',')    as total_quantity_sales,
                    string_agg(coalesce(btq.operator_quantity_sales, '0'), ',') as operator_quantity_sales,
                    string_agg(coalesce(btq.quantity_profit, '0'), ',')         as quantity_profit
             from package_quantities
                    left join (select cast(package_quantities.id as varchar)                                as package_quantity_id,
                                      cast(sum(coalesce(booking_tours.tour_total_price, 0)) as varchar)     as total_quantity_sales,
                                      cast(sum(coalesce(booking_tours.total_operator_price, 0)) as varchar) as operator_quantity_sales,
                                      cast(sum(coalesce(booking_tours.tour_total_price, 0)) -
                                           sum(coalesce(booking_tours.total_operator_price, 0)) as varchar) as quantity_profit
                               from booking_tours
                                      right join package_quantities
                                        on package_quantities.id = booking_tours.package_quantity_id
                               group by package_quantities.id, booking_tours.package_quantity_id) as
                 btq on cast(btq.package_quantity_id as integer) = package_quantities.id
             where is_published = true
             group by package_quantities.package_id) as
    pq on pq.package_id = tour_packages.id
where tour_packages.is_published = true
group by operators.id, concat(users.first_name, ' ', users.last_name), users.email
order by operators.id;