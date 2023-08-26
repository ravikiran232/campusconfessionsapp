import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AnonymousNameCard extends StatelessWidget {
  bool isCurrentUser;
  bool forCurrentUser;
  bool fromAdmin;
  bool isPollEnabled;
  AnonymousNameCard({
    super.key,
    this.isCurrentUser = false,
    this.forCurrentUser = false,
    this.isPollEnabled = false,
    this.fromAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        color: isPollEnabled ? null : const Color.fromARGB(255, 255, 255, 255),
        gradient: isPollEnabled
            ? const LinearGradient(
                colors: [
                  Color.fromARGB(255, 146, 26, 167),
                  Color.fromARGB(255, 206, 84, 227)
                ],
              )
            : null, //target here
      ),
      padding: forCurrentUser
          ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0)
          : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
      child: fromAdmin
          ? isPollEnabled
              ? Shimmer.fromColors(
                  baseColor: Colors.white,
                  highlightColor: Colors.purple,
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 18.0,
                    ),
                  ),
                )
              : const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                )
          : forCurrentUser
              ? isPollEnabled
                  ? Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.purple,
                      child: const Text(
                        'For You',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 18.0,
                        ),
                      ),
                    )
                  : const Text(
                      'For You',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                        fontSize: 18.0,
                      ),
                    )
              : isCurrentUser
                  ? isPollEnabled
                      ? Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor: Colors.purple,
                          child: Text(
                            'Personal',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17.0,
                                color: isPollEnabled
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        )
                      : Text(
                          'Personal',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17.0,
                              color:
                                  isPollEnabled ? Colors.white : Colors.black),
                        )
                  : isPollEnabled
                      ? Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor: Colors.purple,
                          child: Text(
                            'Anonymous',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.0,
                                color: isPollEnabled
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        )
                      : Text(
                          'Anonymous',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.0,
                              color:
                                  isPollEnabled ? Colors.white : Colors.black),
                        ),
    );
  }
}
